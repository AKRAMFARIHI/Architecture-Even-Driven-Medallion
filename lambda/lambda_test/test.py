def lambda_handler(event, context):
    import numpy as np
    import pandas as pd

    return {
        "statusCode": 200,
        "body": {
            "numpy_version": np.__version__,
            "pandas_version": pd.__version__
        }
    }
