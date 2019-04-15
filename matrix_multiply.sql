-- Matrix Multiply Workbook
--
-- Use the Coordinate List representation of a sparse matrix
-- as a table of tuples for the populated matrix values.
--    Matrix A (rownum, colnum, value)
--    Matrix B (rownum, colnum, value)
--
-- Product P(i,j) = ∑ A(i,k) * B(k,j), over all k
-- Note: A x B is only defined when k matches for the matrices
--
-- The matrix product becomes a JOIN and a GROUP BY SUM.
-- JOIN ON A.colnum = B.rownum
--    ensures A.value, B.value has matching k
-- SUM (A.value * B.value) GROUP BY (A.rownum, B.colnum)
--    ensures summation over all k
--
-- Results:
-- Matrix A (10K, 2K) = 20M cells, sparse 17M, 
-- Matrix B (2K, 5K) = 10M cells, sparse 9M, 4.5GB
-- Product (50M cells): 8m on S, 3m52s on M, 1m52 on L, 58s on XL
--
-- Matrix A (1K, 2K) = 2M cells, sparse 1.7M, 850MB
-- Matrix B (2K, 700)= 1.4M cells, sparse 1.3M, 626MB
-- Product (700K cells) = 4s on L
-- 4x =  9s on L
-- 16x = 22s on L x 2 clusters
-- 32x = 40s on L x 2 clusters
-- 128x = 130s on L x 2 clusters

create schema if not exists matrix;

-- Dimensions for Matrix1, Matrix2 and maximum absolute value
-- for the range of matrix values.
--
set (rows1, cols1, rows2, cols2) = (1000, 2000, 2000, 700);
set abs_maxval = 10;
  
-- Generate Matrix 1
-- This is a dense 2-D matrix generated with Snowflake's built-in
-- generator() table function and a cross-join to fill in all cells.
--
create or replace table mat1 as 
  with matcolumns as (
    select
      seq4() + 1 as colnum
    from
      table(generator(rowcount => $cols1))
  ),
  matrows as (
    select
      seq4() + 1 as rownum
    from
      table(generator(rowcount => $rows1))
  )
select
  rownum,
  colnum,
  random(3) % ($abs_maxval+1) as value,
  randstr(512, random(3)) as dummy
from
  matrows
  cross join matcolumns;

-- Generate Matrix 2
-- This is a dense 2-D matrix generated with Snowflake's built-in
-- generator() table function and a cross-join to fill in all cells.
--
create or replace table mat2 as 
  with matcolumns as (
    select
      seq4() + 1 as colnum
    from
      table(generator(rowcount => $cols2))
  ),
  matrows as (
    select
      seq4() + 1 as rownum
    from
      table(generator(rowcount => $rows2))
  )
select
  rownum,
  colnum,
  random(7) % ($abs_maxval+1) as value,
  randstr(512, random(7)) as dummy
from
  matrows
  cross join matcolumns;

-- Optional: make the matrices sparse by deleting
-- some entries based on random value range.
--
delete from mat1
where value IN (0, $abs_maxval);

delete from mat2
where value IN (1, $abs_maxval);
  
-- Check matrix table element counts and values
--
select count(*) element_count
from mat1
union
select count(*)
from mat2;
  
select rownum, count(rownum) as columns from mat1
group by rownum
order by 2, 1
limit 200;

select rownum, count(rownum) as columns from mat2
group by rownum
order by 2, 1
limit 200;

-- Multiply Mat1 x Mat2, result in Matrix_Product
--
create or replace table matrix_product as
SELECT
  mat1.rownum,
  mat2.colnum,
  SUM(mat1.value * mat2.value) as value
FROM
  mat1
  JOIN mat2 ON mat1.colnum = mat2.rownum
GROUP BY
  mat1.rownum,
  mat2.colnum;
  
select * from matrix_product order by rownum, colnum;