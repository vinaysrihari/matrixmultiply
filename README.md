# matrixmultiply
Matrix Multiplication using Snowflake

Use the Coordinate List representation of a sparse matrix
as a table of tuples for the populated matrix values.
  Matrix A (rownum, colnum, value)
  Matrix B (rownum, colnum, value)

Product P(i,j) = ∑ A(i,k) * B(k,j), over all k
Note: A x B is only defined when k matches for the matrices

The matrix product becomes a JOIN and a GROUP BY SUM.
  JOIN ON A.colnum = B.rownum
    ensures A.value, B.value has matching k
  SUM (A.value * B.value) GROUP BY (A.rownum, B.colnum)
    ensures summation over all k
