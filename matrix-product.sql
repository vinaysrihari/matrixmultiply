-- Multiply Mat1 x Mat2, result in Matrix_Product
--
-- create or replace table matrix_product1 as
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