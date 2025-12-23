resource "aws_lambda_layer_version" "pandas_numpy_layer" {
    layer_name = "pandas-numpy-layer"
    filename = "${path.module}/lambda_layer/pandas_numpy_layer.zip"
    compatible_runtimes = ["python3.11"]
    
}