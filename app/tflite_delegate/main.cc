
//
// library link check
//

#include "tensorflow/lite/c/c_api_internal.h"

namespace tflite {
 TfLiteDelegate*  CreateMyDelegate();
}

int main()
{
 auto* my_delegate = tflite::CreateMyDelegate();
 return 0;
}

