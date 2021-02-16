
#include <iostream>
#include <stdio.h>
#include "tensorflow/lite/util.h"
#include "tensorflow/lite/builtin_ops.h"
#include "tensorflow/lite/context_util.h"
#include "tensorflow/lite/kernels/internal/common.h"
#include "tensorflow/lite/c/c_api_internal.h"
#include "tensorflow/lite/c/builtin_op_data.h"
#include "tensorflow/lite/kernels/padding.h"
#include "tensorflow/lite/kernels/internal/tensor_ctypes.h"
#include "tensorflow/lite/kernels/kernel_util.h"
#include "tensorflow/lite/kernels/internal/quantization_util.h"
#include "tensorflow/lite/kernels/internal/round.h"
#include "tfacc_u8.h"

namespace tflite {

const int kTensorNotAllocated = -1;

struct OpParams {
    int32_t optype; //
    int16 pad_width;
    int16 pad_height;
    int16 stride_width;
    int16 stride_height;
    int16 dilation_width_factor;
    int16 dilation_height_factor;
    int16 depth_multiplier;
    float activation_min;
    float activation_max;
    // quantize params
    int32 input_offset;
    int32 weight_offset;
    int32 output_offset;
    int32 output_multiplier;
    int output_shift;
    int32_t *per_channel_multiplier;
    int *per_channel_shift;

};

struct OpData {
    TfLiteIntArray *input;
    TfLiteIntArray *weight;
    TfLiteIntArray *bias;
    TfLiteIntArray *output;
    OpParams *params;
};

OpData *OpDataArrayCreate(size_t size)
{
    OpData* opdata = new OpData;
    opdata->input = TfLiteIntArrayCreate(size);
    opdata->weight = TfLiteIntArrayCreate(size);
    opdata->bias = TfLiteIntArrayCreate(size);
    opdata->output = TfLiteIntArrayCreate(size);
    opdata->params = new OpParams[size];
    return opdata;
}

void OpDataArrayFree(OpData *opdata)
{
    TfLiteIntArrayFree(opdata->input);
    TfLiteIntArrayFree(opdata->weight);
    TfLiteIntArrayFree(opdata->bias);
    TfLiteIntArrayFree(opdata->output);
    delete opdata->params;
    delete opdata;
}

float activation_min(TfLiteFusedActivation activation)
{
    switch(activation){
    case kTfLiteActRelu:
    case kTfLiteActRelu6: return 0.0f;
    case kTfLiteActRelu1: return -1.0f;
    default: return -128.0f;
    }
}
float activation_max(TfLiteFusedActivation activation)
{
    switch(activation){
    case kTfLiteActRelu:  return 127.0f;
    case kTfLiteActRelu6: return 6.0f;
    case kTfLiteActRelu1: return 1.0f;
    default: return 127.0f;
    }
}
#if 0
TfLiteStatus PopulateConvolutionQuantizationParams(
        TfLiteContext* context, const TfLiteTensor* input,
        const TfLiteTensor* filter, const TfLiteTensor* bias, TfLiteTensor* output,
        const TfLiteFusedActivation& activation, int32_t* multiplier, int* shift,
        int32_t* output_activation_min, int32_t* output_activation_max,
        int32_t* per_channel_multiplier, int* per_channel_shift) {
    TF_LITE_ENSURE_EQ(context, input->quantization.type,
            kTfLiteAffineQuantization);
    TF_LITE_ENSURE_EQ(context, filter->quantization.type,
            kTfLiteAffineQuantization);
    // TODO(jianlijianli): Enable bias type check and bias scale == input scale
    // * filter scale for each channel in affine quantization once bias
    // quantization is properly populated.
    // TF_LITE_ENSURE_EQ(context, bias->quantization.type,
    // kTfLiteAffineQuantization);

    // Check data type.
    const auto* affine_quantization =
            reinterpret_cast<TfLiteAffineQuantization*>(filter->quantization.params);
    TF_LITE_ENSURE(context, affine_quantization);
    TF_LITE_ENSURE(context, affine_quantization->scale);
    const bool is_per_channel = affine_quantization->scale->size > 1;
    if (is_per_channel) {
        //  Currently only Int8 is supported for per channel quantization.
        TF_LITE_ENSURE_EQ(context, input->type, kTfLiteInt8);
        TF_LITE_ENSURE_EQ(context, filter->type, kTfLiteInt8);
        TF_LITE_ENSURE_EQ(
                context, affine_quantization->scale->size,
                filter->dims->data[affine_quantization->quantized_dimension]);
    }

    // Populate multiplier and shift using affine quantization.
    const int num_channels = affine_quantization->scale->size;
    const float input_scale = input->params.scale;
    const float output_scale = output->params.scale;
    const float* filter_scales = affine_quantization->scale->data;
    for (int i = 0; i < num_channels; ++i) {
        const double filter_scale = static_cast<double>(filter_scales[i]);
        const double effective_output_scale = static_cast<double>(input_scale) *
                filter_scale /
                static_cast<double>(output_scale);
        int32_t significand;
        int shift;
        QuantizeMultiplier(effective_output_scale, &significand, &shift);
        per_channel_multiplier[i] = significand;
        per_channel_shift[i] = shift;
    }

    // Populate scalar quantization parameters.
    // This check on legacy quantization parameters is kept only for backward
    // compatibility.
    if (input->type == kTfLiteUInt8) {
        // Check bias scale == input scale * filter scale.
        double real_multiplier = 0.0;
        TF_LITE_ENSURE_STATUS(GetQuantizedConvolutionMultipler(
                context, input, filter, bias, output, &real_multiplier));
        int exponent;

        // Populate quantization parameteters with multiplier and shift.
        QuantizeMultiplier(real_multiplier, multiplier, &exponent);
        *shift = -exponent;
        CalculateActivationRangeUint8(activation, output, output_activation_min,
                output_activation_max);
    }
    return kTfLiteOk;
}
#endif

TfLiteStatus OpParamsPrepare(TfLiteContext* context,
        TfLiteTensor* input, TfLiteTensor* filter, TfLiteTensor* bias, TfLiteTensor* output,
        OpParams *opparam, void *tfparams, int32_t optype)
{
    int out_width  = output->dims->data[2];
    int out_height = output->dims->data[1];
    int width  = input->dims->data[2];
    int height = input->dims->data[1];
    int filter_width  = filter->dims->data[2];
    int filter_height = filter->dims->data[1];
    int offset = 0;
    opparam->optype = optype;

    int32_t multiplier;
    int shift;
    int32_t output_activation_min;
    int32_t output_activation_max;
    //    int32_t per_channel_multiplier;
    //    int per_channel_shift;

    opparam->input_offset = -input->params.zero_point;
    opparam->weight_offset = -filter->params.zero_point;
    opparam->output_offset = output->params.zero_point;

    if(optype == kTfLiteBuiltinConv2d){
        auto* params = reinterpret_cast<TfLiteConvParams*>(tfparams);
        //       fprintf(stderr,"Pparam %d %d %d %d %d %d\n",params->padding,params->stride_width,params->stride_height,
        //               params->dilation_width_factor,params->dilation_height_factor,params->activation);
        opparam->pad_height =
                ComputePaddingWithOffset(params->stride_height, params->dilation_height_factor, height,
                        filter_height, out_height, &offset);
        opparam->pad_width =
                ComputePaddingWithOffset(params->stride_width, params->dilation_width_factor, width,
                        filter_width, out_width, &offset);
        opparam->stride_width = params->stride_width;
        opparam->stride_height = params->stride_height;
        opparam->dilation_width_factor = params->dilation_width_factor;
        opparam->dilation_height_factor = params->dilation_height_factor;
        opparam->depth_multiplier = 1;
        opparam->activation_min = activation_min(params->activation);
        opparam->activation_max = activation_max(params->activation);
        //       fprintf(stderr,"Pp %d %g %g pad:%d %d\n",
        //             params->activation,opparam->activation_min, opparam->activation_max,
        //           opparam->stride_width,opparam->stride_height);
        if(output->type != kTfLiteFloat32){
            opparam->per_channel_multiplier = new int32_t[output->dims->data[3]];
            opparam->per_channel_shift = new int[output->dims->data[3]];
            PopulateConvolutionQuantizationParams(context, input, filter, bias, output,
                    params->activation, &multiplier, &shift,
                    &output_activation_min, &output_activation_max,
                    opparam->per_channel_multiplier, opparam->per_channel_shift);
            opparam->activation_min = output_activation_min;
            opparam->activation_max = output_activation_max;
        }
        //       fprintf(stderr,"Pp %d %g %g\n",params->activation,opparam->activation_min, opparam->activation_max);
    }else if(optype == kTfLiteBuiltinDepthwiseConv2d){
        auto* params = reinterpret_cast<TfLiteDepthwiseConvParams*>(tfparams);
        opparam->pad_height =
                ComputePaddingWithOffset(params->stride_height, params->dilation_height_factor, height,
                        filter_height, out_height, &offset);
        opparam->pad_width =
                ComputePaddingWithOffset(params->stride_width, params->dilation_width_factor, width,
                        filter_width, out_width, &offset);
        opparam->stride_width = params->stride_width;
        opparam->stride_height = params->stride_height;
        opparam->dilation_width_factor = params->dilation_width_factor;
        opparam->dilation_height_factor = params->dilation_height_factor;
        opparam->depth_multiplier = params->depth_multiplier;
        opparam->activation_min = activation_min(params->activation);
        opparam->activation_max = activation_max(params->activation);
        if(output->type != kTfLiteFloat32){
            opparam->per_channel_multiplier = new int32_t[output->dims->data[3]];
            opparam->per_channel_shift = new int[output->dims->data[3]];
            PopulateConvolutionQuantizationParams(context, input, filter, bias, output,
                    params->activation, &multiplier, &shift,
                    &output_activation_min, &output_activation_max,
                    opparam->per_channel_multiplier, opparam->per_channel_shift);
            opparam->activation_min = output_activation_min;
            opparam->activation_max = output_activation_max;
        }
    }else{  // error
        TF_LITE_ENSURE_STATUS(kTfLiteError);
    }
    opparam->output_multiplier = multiplier;
    opparam->output_shift = shift;

    return kTfLiteOk;
}

inline int32 _MultiplyByQuantizedMultiplier(int32 x, int32 quantized_multiplier, int shift) {    // right shift only
    int32 xx = ((int64_t)x * ((quantized_multiplier)>>15)) >> 16;
    //    int32 dp = (1 << (-shift-1));
    int32 mask = (1 << (-shift)) - 1;
    int32 th = (mask >> 1) + (x < 0);
    int32 rem = xx & mask;
    return (xx >> -shift) + (rem > th);
}

inline int _Offset(const RuntimeShape& shape, int i0, int i1, int i2, int i3) {
    //  TFLITE_DCHECK_EQ(shape.DimensionsCount(), 4);
    const int* dims_data = reinterpret_cast<const int*>(shape.DimsDataUpTo4D());
    //  TFLITE_DCHECK(i0 >= 0 && i0 < dims_data[0]);
    //  TFLITE_DCHECK(i1 >= 0 && i1 < dims_data[1]);
    //  TFLITE_DCHECK(i2 >= 0 && i2 < dims_data[2]);
    //  TFLITE_DCHECK(i3 >= 0 && i3 < dims_data[3]);
    return ((i0 * dims_data[1] + i1) * dims_data[2] + i2) * dims_data[3] + i3;
}

//--- for tfacc_u8 debug ----
static int accmax = 0;
static int n_stage = 0;
static int dumpfrom = 66;
static int dumpto = 65;
static FILE *dfp1 = NULL;


inline void Conv3quant(// conv / dwconv
        int dwen,
        OpParams *params,
        TfLiteTensor* input,    // uint8
        TfLiteTensor* filter,   // uint8
        TfLiteTensor* bias,     // int32
        TfLiteTensor* output){  // uint8

    const RuntimeShape& input_shape = GetTensorShape(input);
    const uint8* input_data = GetTensorData<uint8>(input);
    const RuntimeShape& filter_shape = GetTensorShape(filter);
    const uint8* filter_data = GetTensorData<uint8>(filter);
    const RuntimeShape& bias_shape = GetTensorShape(bias);
    const int32* bias_data = GetTensorData<int32>(bias);
    const RuntimeShape& output_shape = GetTensorShape(output);
    uint8* output_data  = GetTensorData<uint8>(output);

    const int strW = params->stride_width;
    const int strH = params->stride_height;
    const int dilW = params->dilation_width_factor;
    const int dilH = params->dilation_height_factor;
    const int padW = params->pad_width;
    const int padH = params->pad_height;
    const int32 actmin = (int32)params->activation_min;
    const int32 actmax = (int32)params->activation_max;

    const int32 in_offs  = params->input_offset;
    const int32 fil_offs = params->weight_offset;
    const int32 out_offs = params->output_offset;
    const int32 out_mult = params->output_multiplier;
    const int out_shift  = -params->output_shift;

    const int inH   = input_shape.Dims(1);
    const int inW   = input_shape.Dims(2);
    const int inC   = input_shape.Dims(3);
    const int filH  = filter_shape.Dims(1);
    const int filW  = filter_shape.Dims(2);
    const int filC  = filter_shape.Dims(3);
    const int outH  = output_shape.Dims(1);
    const int outW  = output_shape.Dims(2);
    const int outC  = output_shape.Dims(3);
    const int fil_size = filH * filW * filC;

    const int depthmul = dwen ? params->depth_multiplier : 1;
    int ch1C = dwen ? inC : outC;
    int ch2C = dwen ? 1 : inC;
    int finc = dwen ? filC : 1;
    int pH = outW * outH; // (outWH + (Np-1)) / Np

#define PACK3(a,b,c)    (((a)<<6)|((b)<<3)|(c))

    set_data(kTfaccOutput, output_data, output->bytes);
    set_data(kTfaccInput,  (void*)input_data, input->bytes);
    set_data(kTfaccFilter, (void*)filter_data, filter->bytes);
    set_data(kTfaccBias,   (void*)bias_data, bias->bytes);

    set_param(kTfaccNstage, n_stage);    // nstage, 4
    set_param(kTfaccDWen,   dwen); // dwen 5
    set_param(kTfaccRun,    0);    // run

    set_accparam(0, inH);
    set_accparam(1, inW);
    set_accparam(2, inC);
    set_accparam(3, filH);
    set_accparam(4, filW);
    set_accparam(5, filC);
    set_accparam(6, outH);
    set_accparam(7, outW);
    set_accparam(8, outC);
    set_accparam(9, pH);
    set_accparam(10, PACK3(strH,dilH,padH));
    set_accparam(11, PACK3(strW,dilW,padW));
    set_accparam(12, depthmul);
    set_accparam(13, actmin);
    set_accparam(14, actmax);
    set_accparam(15, in_offs);
    set_accparam(16, fil_offs);
    set_accparam(17, out_offs);
    set_accparam(18, out_mult>>15);
    set_accparam(19, -out_shift);

    set_param(kTfaccRun, 1);    // run tfacc
#ifdef ULTRA96
    while(get_param(kTfaccRun))
        ;

//    if(n_stage == 0){
    get_outdata(output_data, output->bytes);
    n_stage++;
    return;
//    }
//    n_stage++;
//    return;
#endif

    if(dumpfrom <= n_stage && dumpto >= n_stage){
        char fn[80];
        sprintf(fn, "tdump-%d-u8.in", n_stage);
        fprintf(stderr,"*** dump : %s\n", fn);
        dfp1 = fopen(fn, "w");
        fprintf(dfp1,"-1: dwen %d\n",dwen);
        fprintf(dfp1,"0: inH %d\n",inH);
        fprintf(dfp1,"1: inW %d\n",inW);
        fprintf(dfp1,"2: inC %d\n",inC);
        fprintf(dfp1,"3: filH %d\n",filH);
        fprintf(dfp1,"4: filW %d\n",filW);
        fprintf(dfp1,"5: filC %d\n",filC);
        fprintf(dfp1,"6: outH %d\n",outH);
        fprintf(dfp1,"7: outW %d\n",outW);
        fprintf(dfp1,"8: outC %d\n",outC);
        fprintf(dfp1,"9: pH %d\n",pH);
        fprintf(dfp1,"10: {strH,dilH,padH} %d\n",PACK3(strH,dilH,padH));
        fprintf(dfp1,"11: {strW,dilW,padW} %d\n",PACK3(strW,dilW,padW));
        fprintf(dfp1,"12: depthmul %d\n",depthmul);  //
        fprintf(dfp1,"13: actmin %d\n",actmin);
        fprintf(dfp1,"14: actmax %d\n",actmax);
        fprintf(dfp1,"15: in_offs %d\n",in_offs);
        fprintf(dfp1,"16: fil_offs %d\n",fil_offs);
        fprintf(dfp1,"17: out_offs %d\n",out_offs);
        fprintf(dfp1,"18: out_mult %d\n",out_mult>>15);
        fprintf(dfp1,"19: out_shift %d\n",-out_shift);
        fprintf(dfp1,"input: %zd\n", input->bytes);
        fprintf(dfp1,"filter: %zd\n", filter->bytes);
        fprintf(dfp1,"bias: %zd\n", bias->bytes);
        fprintf(dfp1,"output: %zd\n", output->bytes);
        fwrite(input_data, 1, input->bytes, dfp1);
        fwrite(filter_data, 1, filter->bytes, dfp1);
        fwrite(bias_data, 1, bias->bytes, dfp1);
    }

    fprintf(stderr,"%2d %sconv: (acc x %d >>%2d+16)+%-3d %3d %d  ", n_stage, dwen?"dw":"  ",
            out_mult>>15,-out_shift,out_offs,actmin,actmax);
    fprintf(stderr,"o: %3d %3d %3d f: %3d %3d %3d i: %3d %3d %3d  %d  %d %d  %d %d  %d %d\n",
            outH,outW,outC, filH,filW,filC, inH,inW,inC, depthmul,strH,strW,dilH,dilW,padH,padW);

/*    fprintf(stderr,"%2d in:%p,%d fil:%p bias:%p out:%p,%d %x\n", n_stage, input_data, in_cma((void*)input_data), filter_data, bias_data, output_data,
 in_cma(output_data), (uint32_t)cma_get_phy_addr(output_data));
*/
    uint8* outpt = output_data;
//    uint8* refout = (uint8*)malloc(output->bytes);
//    uint8* outpt = refout;

    int in_y0 = - padH;
    for (int out_y = 0; out_y < outH; ++out_y, in_y0 += strH) {
        int in_x0 = - padW;
        for (int out_x = 0; out_x < outW; ++out_x, in_x0 += strW) {
            for (int out_c = 0; out_c < ch1C*depthmul; out_c++) {
                //for (int ch1 = 0; ch1 < ch1C; ++ch1) {
                //for (int m = 0; m < depthmul; m++) {
                //const int out_c = m + ch1 * depthmul;
                const int ch1 = out_c / depthmul;
                int32 acc = 0;
                const uint8* filpt = dwen ? &filter_data[out_c] : &filter_data[fil_size * ch1];

                for (int fil_y = 0; fil_y < filH; ++fil_y) {
                    const int in_y = in_y0 + dilH * fil_y;
                    const int in_y_valid = (in_y >= 0) && (in_y < inH);
                    const int in_y_ofs = in_y * inW * inC;
                    const uint8* inpt = dwen ? &input_data[in_y_ofs + ch1] : &input_data[in_y_ofs];
                    for (int fil_x = 0; fil_x < filW; ++fil_x) {
                        const int in_x = in_x0 + dilW * fil_x;
                        const int in_valid = (in_x >= 0) && (in_x < inW) && in_y_valid;
                        const uint8* inpt2 = &inpt[in_x * inC];
                        for (int in_c = 0; in_c < ch2C; ++in_c) {
                            // If the location is outside the bounds of the input image,
                            // use zero as a default value.
                            int32 fil_d = *filpt;
                            filpt += finc;
                            int32 in_d = 0;
                            if (in_valid) {
                                in_d = inpt2[in_c];
                                acc += (fil_d + fil_offs) * (in_d + in_offs);
                            }
                       }
                    }
                }
                if (bias_data) {
                    acc += bias_data[out_c];
                }
                acc = _MultiplyByQuantizedMultiplier(acc, out_mult, out_shift) + out_offs;
                acc = std::max(acc, actmin);
                acc = std::min(acc, actmax);
                //output_data[_Offset(output_shape, batch, out_y, out_x, out_c)] = static_cast<uint8>(acc);
                *outpt++ = static_cast<uint8>(acc);
                //    }
            }
        }
    }
/*    if(0 && n_stage == 12)
    for(int i = 0; i < output->bytes; i++){
        if(output_data[i] != refout[i]){
            printf("%d %2x %2x\n", i, output_data[i], refout[i]);
        }
    }
*/
    if(dfp1){
        fwrite(output_data, 1, output->bytes, dfp1);
        fclose(dfp1);
        dfp1 = NULL;
    }

    n_stage++;
}

inline void Conv2quant(
        OpParams *params,
        TfLiteTensor* input,    // uint8
        TfLiteTensor* filter,   // uint8
        TfLiteTensor* bias,     // int32
        TfLiteTensor* output){  // uint8

    const RuntimeShape& input_shape = GetTensorShape(input);
    const uint8* input_data = GetTensorData<uint8>(input);
    const RuntimeShape& filter_shape = GetTensorShape(filter);
    const uint8* filter_data = GetTensorData<uint8>(filter);
    const RuntimeShape& bias_shape = GetTensorShape(bias);
    const int32* bias_data = GetTensorData<int32>(bias);
    const RuntimeShape& output_shape = GetTensorShape(output);
    uint8* output_data  = GetTensorData<uint8>(output);

    const int stride_width = params->stride_width;
    const int stride_height = params->stride_height;
    const int dilation_width_factor = params->dilation_width_factor;
    const int dilation_height_factor = params->dilation_height_factor;
    const int pad_width = params->pad_width;
    const int pad_height = params->pad_height;
    const int32 output_activation_min = (int32)params->activation_min;
    const int32 output_activation_max = (int32)params->activation_max;

    const int32 input_offset = params->input_offset;
    const int32 filter_offset = params->weight_offset;
    const int32 output_offset = params->output_offset;
    const int32 output_multiplier = params->output_multiplier;
    const int output_shift = -params->output_shift;

    const int batches = 1;
    const int input_depth   = MatchingDim(input_shape, 3, filter_shape, 3);
    const int output_depth  = MatchingDim(filter_shape, 0, output_shape, 3);
    const int input_height  = input_shape.Dims(1);
    const int input_width   = input_shape.Dims(2);
    const int filter_height = filter_shape.Dims(1);
    const int filter_width  = filter_shape.Dims(2);
    const int output_height = output_shape.Dims(1);
    const int output_width  = output_shape.Dims(2);

    fprintf(stderr,"conv:   (acc x %d >>%2d+15)+%-3d %3d %d  ",
            output_multiplier>>16,-output_shift,output_offset,
            output_activation_min,output_activation_max);
    fprintf(stderr,"o: %3d %3d %3d f: %3d %3d %3d i: %3d %3d %3d  -  %d %d  %d %d  %d %d %d\n",
            output_height,output_width,output_depth,filter_height,filter_width,filter_shape.Dims(3),
            input_height,input_width,input_depth,
            stride_height,stride_width,dilation_height_factor,dilation_width_factor,
            pad_height,pad_width, accmax);


    uint8* outpt = output_data;
    for (int batch = 0; batch < batches; ++batch) {
        int in_y0 = - pad_height;
        for (int out_y = 0; out_y < output_height; ++out_y, in_y0 += stride_height) {
            int in_x0 = - pad_width;
            for (int out_x = 0; out_x < output_width; ++out_x, in_x0 += stride_width) {
                for (int out_c = 0; out_c < output_depth; ++out_c) {
                    int32 acc = 0;
                    const uint8* filpt = &filter_data[_Offset(filter_shape, out_c, 0, 0, 0)];
                    for (int fil_y = 0; fil_y < filter_height; ++fil_y) {
                        const int in_y = in_y0 + dilation_height_factor * fil_y;
                        const int in_y_valid = (in_y >= 0) && (in_y < input_height);
                        const uint8* inpt = &input_data[_Offset(input_shape, batch, in_y, 0, 0)];
                        for (int fil_x = 0; fil_x < filter_width; ++fil_x) {
                            const int in_x = in_x0 + dilation_width_factor * fil_x;
                            const int in_valid = (in_x >= 0) && (in_x < input_width) && in_y_valid;
                            const uint8* inpt2 = &inpt[in_x * input_depth];
                            for (int in_c = 0; in_c < input_depth; ++in_c) {
                                // If the location is outside the bounds of the input image,
                                // use zero as a default value.
                                int32 filter_val = *filpt++;
                                int32 input_val = 0;
                                if (in_valid) {
                                    input_val = inpt2[in_c];
                                    //  int32 input_val  = input_data[_Offset(input_shape, batch, in_y, in_x, in_c)];
                                    //  int32 filter_val = filter_data[_Offset(filter_shape, out_c, fil_y, fil_x, in_c)];
                                    acc += (filter_val + filter_offset) * (input_val + input_offset);
                                }
                            }
                        }
                    }
                    if (bias_data) {
                        acc += bias_data[out_c];
                    }
                    accmax = std::max(abs(acc), accmax);
                    acc = _MultiplyByQuantizedMultiplier(acc, output_multiplier, output_shift);
                    acc += output_offset;
                    acc = std::max(acc, output_activation_min);
                    acc = std::min(acc, output_activation_max);
                    //output_data[_Offset(output_shape, batch, out_y, out_x, out_c)] = static_cast<uint8>(acc);
                    *outpt++ = static_cast<uint8>(acc);
                }
            }
        }
    }
}
inline void Conv2quantPerChannel(
        OpParams *params,
        TfLiteTensor* input,    // int8
        TfLiteTensor* filter,   // int8
        TfLiteTensor* bias,     // int32
        TfLiteTensor* output){  // int8

    const RuntimeShape& input_shape = GetTensorShape(input);
    const int8* input_data = GetTensorData<int8>(input);
    const RuntimeShape& filter_shape = GetTensorShape(filter);
    const int8* filter_data = GetTensorData<int8>(filter);
    const RuntimeShape& bias_shape = GetTensorShape(bias);
    const int32* bias_data = GetTensorData<int32>(bias);
    const RuntimeShape& output_shape = GetTensorShape(output);
    int8* output_data  = GetTensorData<int8>(output);
    int32_t* output_multiplier = params->per_channel_multiplier;
    int* output_shift = params->per_channel_shift;

    // Get parameters.
    const int32 input_offset = params->input_offset;  // r = s(q - Z)
    const int stride_width = params->stride_width;
    const int stride_height = params->stride_height;
    const int dilation_width_factor = params->dilation_width_factor;
    const int dilation_height_factor = params->dilation_height_factor;
    const int32 output_offset = params->output_offset;
    const int pad_width = params->pad_width;
    const int pad_height = params->pad_height;

    // Set min and max value of the output.
    const int32 output_activation_min = std::numeric_limits<int8_t>::min();
    const int32 output_activation_max = std::numeric_limits<int8_t>::max();

    // Sanity check.
    TFLITE_DCHECK_LE(output_activation_min, output_activation_max);
    TFLITE_DCHECK_EQ(input_shape.DimensionsCount(), 4);
    TFLITE_DCHECK_EQ(filter_shape.DimensionsCount(), 4);
    TFLITE_DCHECK_EQ(output_shape.DimensionsCount(), 4);
    const int batches = MatchingDim(input_shape, 0, output_shape, 0);
    const int input_depth = MatchingDim(input_shape, 3, filter_shape, 3);
    const int output_depth = MatchingDim(filter_shape, 0, output_shape, 3);
    if (bias_data) {
        TFLITE_DCHECK_EQ(bias_shape.FlatSize(), output_depth);
    }

    // Check dimensions of the tensors.
    const int input_height = input_shape.Dims(1);
    const int input_width = input_shape.Dims(2);
    const int filter_height = filter_shape.Dims(1);
    const int filter_width = filter_shape.Dims(2);
    const int output_height = output_shape.Dims(1);
    const int output_width = output_shape.Dims(2);

    fprintf(stderr,"conv:   (acc x %d >>%2d+15)%+4d %3d %d  ",
            output_multiplier[0]>>16,-output_shift[0],output_offset,
            output_activation_min,output_activation_max);
    fprintf(stderr,"o: %3d %3d %3d f: %3d %3d %3d i: %3d %3d %3d  -  %d %d  %d %d  %d %d\n",
            output_height,output_width,output_depth,filter_height,filter_width,filter_shape.Dims(3),
            input_height,input_width,input_depth,
            stride_height,stride_width,dilation_height_factor,dilation_width_factor,
            pad_height,pad_width);

    int8* outpt = output_data;
    for (int batch = 0; batch < batches; ++batch) {
        for (int out_y = 0; out_y < output_height; ++out_y) {
            for (int out_x = 0; out_x < output_width; ++out_x) {
                for (int out_c = 0; out_c < output_depth; ++out_c) {
                    const int in_x0 = (out_x * stride_width) - pad_width;
                    const int in_y0 = (out_y * stride_height) - pad_height;
                    int32 acc = 0;
                    int8* filpt = (int8*)&filter_data[_Offset(filter_shape, out_c, 0, 0, 0)];
                    for (int fil_y = 0; fil_y < filter_height; ++fil_y) {
                        for (int fil_x = 0; fil_x < filter_width; ++fil_x) {
                            for (int in_c = 0; in_c < input_depth; ++in_c) {
                                const int in_x = in_x0 + dilation_width_factor * fil_x;
                                const int in_y = in_y0 + dilation_height_factor * fil_y;
                                int32 filter_val = *filpt++;
                                // Zero padding by omitting the areas outside the image.
                                const bool is_point_inside_image =
                                        (in_x >= 0) && (in_x < input_width) && (in_y >= 0) &&
                                        (in_y < input_height);
                                if (is_point_inside_image) {
                                    int32 input_val = input_data[_Offset(input_shape, batch, in_y,
                                            in_x, in_c)];
                                    //int32 filter_val =
                                    //    filter_data[_Offset(filter_shape, out_c, fil_y,
                                    //                       fil_x, in_c)];
                                    // Accumulate with 32 bits accumulator.
                                    // In the nudging process during model quantization, we force
                                    // real value of 0.0 be represented by a quantized value. This
                                    // guarantees that the input_offset is a int8, even though it
                                    // is represented using int32.
                                    // int32 += int8 * (int8 - int8) so the highest value we can
                                    // get from each accumulation is [-127, 127] * ([-128, 127] -
                                    // [-128, 127]), which is [-32512, 32512]. log2(32512)
                                    // = 14.98, which means we can accumulate at least 2^16
                                    // multiplications without overflow. The accumulator is
                                    // applied to a filter so the accumulation logic will hold as
                                    // long as the filter size (fil_y * fil_x * in_c)
                                    // does not exceed 2^16, which is the case in all the models
                                    // we have seen so far.
                                    // TODO(jianlijianli): Add a check to make sure the
                                    // accumulator depth is smaller than 2^16.
                                    acc += filter_val * (input_val + input_offset);
                                }
                            }
                        }
                    }

                    if (bias_data) {
                        acc += bias_data[out_c];
                    }
                    acc = _MultiplyByQuantizedMultiplier(
                            acc, output_multiplier[out_c], output_shift[out_c]);
                    acc += output_offset;
                    acc = std::max(acc, output_activation_min);
                    acc = std::min(acc, output_activation_max);
                    //output_data[_Offset(output_shape, batch, out_y, out_x, out_c)] =
                    *outpt++ = static_cast<int8_t>(acc);
                }
            }
        }
    }
}

inline void Conv2(
        OpParams *params,
        const RuntimeShape& input_shape, const float* input_data,
        const RuntimeShape& filter_shape, const float* filter_data,
        const RuntimeShape& bias_shape, const float* bias_data,
        const RuntimeShape& output_shape, float* output_data) {

    const int stride_width = params->stride_width;
    const int stride_height = params->stride_height;
    const int dilation_width_factor = params->dilation_width_factor;
    const int dilation_height_factor = params->dilation_height_factor;
    const int pad_width = params->pad_width;
    const int pad_height = params->pad_height;
    const float output_activation_min = params->activation_min;
    const float output_activation_max = params->activation_max;

    const int batches = 1;
    const int input_depth   = MatchingDim(input_shape, 3, filter_shape, 3);
    const int output_depth  = MatchingDim(filter_shape, 0, output_shape, 3);
    const int input_height  = input_shape.Dims(1);
    const int input_width   = input_shape.Dims(2);
    const int filter_height = filter_shape.Dims(1);
    const int filter_width  = filter_shape.Dims(2);
    const int output_height = output_shape.Dims(1);
    const int output_width  = output_shape.Dims(2);

    /*    int i = 0;
fprintf(stderr," conv:%d,%d,%d,%d %d,%d %d,%d %d%d %d%d %d%d %2.0f %2.0f :\n",
        input_depth,output_depth,input_height,input_width,filter_height,filter_width,output_height,output_width,
        stride_width,stride_height,dilation_width_factor,dilation_height_factor,pad_width,pad_height,
        output_activation_min,output_activation_max);
     */
    float *outpt = output_data;
    for (int batch = 0; batch < batches; ++batch) {
        for (int out_y = 0; out_y < output_height; ++out_y) {
            const int in_y0 = (out_y * stride_height) - pad_height;
            for (int out_x = 0; out_x < output_width; ++out_x) {
                const int in_x0 = (out_x * stride_width) - pad_width;
                for (int out_c = 0; out_c < output_depth; ++out_c) {
                    //const int in_x0 = (out_x * stride_width) - pad_width;
                    //const int in_y0 = (out_y * stride_height) - pad_height;
                    float total = 0.f;
                    const float *filpt = &filter_data[_Offset(filter_shape, out_c, 0, 0, 0)];
                    for (int fil_y = 0; fil_y < filter_height; ++fil_y) {
                        const int in_y = in_y0 + dilation_height_factor * fil_y;
                        const int in_y_valid = (in_y >= 0) && (in_y < input_height);
                        const float* inpt = &input_data[_Offset(input_shape, batch, in_y, 0, 0)];
                        for (int fil_x = 0; fil_x < filter_width; ++fil_x) {
                            const int in_x = in_x0 + dilation_width_factor * fil_x;
                            const int in_valid = (in_x >= 0) && (in_x < input_width) && in_y_valid;
                            const float* inpt2 = &inpt[in_x * input_depth];
                            for (int in_c = 0; in_c < input_depth; ++in_c) {
                                //const int in_x = in_x0 + dilation_width_factor * fil_x;
                                //const int in_y = in_y0 + dilation_height_factor * fil_y;
                                float filter_value = *filpt++;
                                // If the location is outside the bounds of the input image,
                                // use zero as a default value.
                                if (in_valid) {
                                    float input_value = inpt2[in_c];
                                    //input_data[_Offset(input_shape, batch, in_y, in_x, in_c)];
                                    //float filter_value =filter_data[_Offset(filter_shape, out_c, fil_y, fil_x, in_c)];
                                    total += (input_value * filter_value);
                                }
                            }
                        }
                    }
                    float bias_value = 0.0f;
                    if (bias_data) {
                        bias_value = bias_data[out_c];
                    }
                    //                   if(i < 10)fprintf(stderr,"%4.2f ", total + bias_value);
                    //                   i++;
                    //output_data[_Offset(output_shape, batch, out_y, out_x, out_c)] =
                    *outpt++ = ActivationFunctionWithMinMax(total + bias_value, output_activation_min, output_activation_max);
                }
            }
        }
    }
    //    for(int i = 0; i < 10; i++) fprintf(stderr,"%4.2f ", output_data[i]);
    //    fprintf(stderr,"i %d\n", i);
}

static inline void DepthwiseConv2quant(
        OpParams *params,
        TfLiteTensor* input,
        TfLiteTensor* filter,
        TfLiteTensor* bias,
        TfLiteTensor* output){

    const RuntimeShape& input_shape = GetTensorShape(input);
    const uint8* input_data = GetTensorData<uint8>(input);
    const RuntimeShape& filter_shape = GetTensorShape(filter);
    const uint8* filter_data = GetTensorData<uint8>(filter);
    const RuntimeShape& bias_shape = GetTensorShape(bias);
    const int32* bias_data = GetTensorData<int32>(bias);
    const RuntimeShape& output_shape = GetTensorShape(output);
    uint8* output_data  = GetTensorData<uint8>(output);

    const int depth_multiplier = params->depth_multiplier;
    const int stride_width = params->stride_width;
    const int stride_height = params->stride_height;
    const int dilation_width_factor = params->dilation_width_factor;
    const int dilation_height_factor = params->dilation_height_factor;
    const int pad_width = params->pad_width;
    const int pad_height = params->pad_height;
    const int32 output_activation_min = (int32)params->activation_min;
    const int32 output_activation_max = (int32)params->activation_max;

    const int32 input_offset = params->input_offset;
    const int32 filter_offset = params->weight_offset;
    const int32 output_offset = params->output_offset;
    const int32 output_multiplier = params->output_multiplier;
    const int output_shift = -params->output_shift;

    const int batches = 1;
    const int output_depth = MatchingDim(filter_shape, 3, output_shape, 3);
    const int input_height = input_shape.Dims(1);
    const int input_width = input_shape.Dims(2);
    const int input_depth = input_shape.Dims(3);
    const int filter_height = filter_shape.Dims(1);
    const int filter_width = filter_shape.Dims(2);
    const int output_height = output_shape.Dims(1);
    const int output_width = output_shape.Dims(2);
    TFLITE_DCHECK_EQ(output_depth, input_depth * depth_multiplier);
    TFLITE_DCHECK_EQ(bias_shape.FlatSize(), output_depth);

    fprintf(stderr,"dwconv: (acc x %d >>%2d+15)+%-3d %3d %d  ",
            output_multiplier>>16,-output_shift,output_offset,
            output_activation_min,output_activation_max);
    fprintf(stderr,"o: %3d %3d %3d f: %3d %3d %3d i: %3d %3d %3d  %d  %d %d  %d %d  %d %d %d\n",
            output_height,output_width,output_depth,filter_height,filter_width,filter_shape.Dims(3),
            input_height,input_width,input_depth,
            depth_multiplier,stride_height,stride_width,dilation_height_factor,dilation_width_factor,
            pad_height,pad_width,accmax);

    uint8* outpt = output_data;
    for (int batch = 0; batch < batches; ++batch) {
        int in_y0 = - pad_height;
        for (int out_y = 0; out_y < output_height; ++out_y, in_y0 += stride_height) {
            int in_x0 = - pad_width;
            for (int out_x = 0; out_x < output_width; ++out_x, in_x0 += stride_width) {
                for (int in_c = 0; in_c < input_depth; ++in_c) {
                    for (int m = 0; m < depth_multiplier; m++) {
                        const int out_c = m + in_c * depth_multiplier;
                        int32 acc = 0;
                        uint8* filpt = (uint8*)&filter_data[_Offset(filter_shape, 0, 0, 0, out_c)];
                        for (int fil_y = 0; fil_y < filter_height; ++fil_y) {
                            const int in_y = in_y0 + dilation_height_factor * fil_y;
                            const int in_y_valid = (in_y >= 0) && (in_y < input_height);
                            const uint8* inpt = &input_data[_Offset(input_shape, batch, in_y, 0, in_c)];
                            for (int fil_x = 0; fil_x < filter_width; ++fil_x) {
                                const int in_x = in_x0 + dilation_width_factor * fil_x;
                                const int in_valid = (in_x >= 0) && (in_x < input_width) && in_y_valid;
                                const uint8* inpt2 = &inpt[in_x * input_depth];
                                // If the location is outside the bounds of the input image,
                                // use zero as a default value.
                                int32 filter_val = *filpt;
                                filpt += filter_shape.Dims(3);
                                if (in_valid) {
                                    int32 input_val = *inpt2;
                                    //[in_x*input_depth];
                                    //int32 input_val = input_data[_Offset(input_shape, b, in_y, in_x, in_c)];
                                    //int32 filter_val = filter_data[_Offset(filter_shape, 0, fil_y, fil_x, out_c)];
                                    acc += (filter_val + filter_offset) * (input_val + input_offset);
                                }
                            }
                        }
                        if (bias_data) {
                            acc += bias_data[out_c];
                        }
                        accmax = std::max(abs(acc), accmax);
                        acc = _MultiplyByQuantizedMultiplier(acc, output_multiplier, output_shift);
                        acc += output_offset;
                        acc = std::max(acc, output_activation_min);
                        acc = std::min(acc, output_activation_max);
                        //   output_data[_Offset(output_shape, batch, out_y, out_x, out_c)] = static_cast<uint8>(acc);
                        *outpt++ = static_cast<uint8>(acc);
                    }
                }
            }
        }
    }
}

inline void DepthwiseConv2PerChannel(
        OpParams *params,
        TfLiteTensor* input,
        TfLiteTensor* filter,
        TfLiteTensor* bias,
        TfLiteTensor* output){

    const RuntimeShape& input_shape = GetTensorShape(input);
    const int8* input_data = GetTensorData<int8>(input);
    const RuntimeShape& filter_shape = GetTensorShape(filter);
    const int8* filter_data = GetTensorData<int8>(filter);
    const RuntimeShape& bias_shape = GetTensorShape(bias);
    const int32* bias_data = GetTensorData<int32>(bias);
    const RuntimeShape& output_shape = GetTensorShape(output);
    int8* output_data  = GetTensorData<int8>(output);
    int32_t* output_multiplier = params->per_channel_multiplier;
    int* output_shift = params->per_channel_shift;
    const int32 input_offset = params->input_offset;  // r = s(q - Z)
    const int32 output_offset = params->output_offset;

    const int depth_multiplier = params->depth_multiplier;
    const int stride_width = params->stride_width;
    const int stride_height = params->stride_height;
    const int dilation_width_factor = params->dilation_width_factor;
    const int dilation_height_factor = params->dilation_height_factor;
    const int pad_width = params->pad_width;
    const int pad_height = params->pad_height;
    //   const int32 output_activation_min = (int32)params->activation_min;
    //   const int32 output_activation_max = (int32)params->activation_max;
    const int32 output_activation_min = std::numeric_limits<int8_t>::min();
    const int32 output_activation_max = std::numeric_limits<int8_t>::max();

    // Check dimensions of the tensors.
    TFLITE_DCHECK_EQ(input_shape.DimensionsCount(), 4);
    TFLITE_DCHECK_EQ(filter_shape.DimensionsCount(), 4);
    TFLITE_DCHECK_EQ(output_shape.DimensionsCount(), 4);

    TFLITE_DCHECK_LE(output_activation_min, output_activation_max);
    const int batches = MatchingDim(input_shape, 0, output_shape, 0);
    const int output_depth = MatchingDim(filter_shape, 3, output_shape, 3);
    const int input_height = input_shape.Dims(1);
    const int input_width = input_shape.Dims(2);
    const int input_depth = input_shape.Dims(3);
    const int filter_height = filter_shape.Dims(1);
    const int filter_width = filter_shape.Dims(2);
    const int output_height = output_shape.Dims(1);
    const int output_width = output_shape.Dims(2);
    TFLITE_DCHECK_EQ(output_depth, input_depth * depth_multiplier);
    TFLITE_DCHECK_EQ(bias_shape.FlatSize(), output_depth);

    fprintf(stderr,"dwconv: (acc x %d >>%2d+15)%+4d %3d %d  ",
            output_multiplier[0]>>16,-output_shift[0],output_offset,
            output_activation_min,output_activation_max);
    fprintf(stderr,"o: %3d %3d %3d f: %3d %3d %3d i: %3d %3d %3d  %d  %d %d  %d %d  %d %d\n",
            output_height,output_width,output_depth,filter_height,filter_width,filter_shape.Dims(3),
            input_height,input_width,input_depth,
            depth_multiplier,stride_height,stride_width,dilation_height_factor,dilation_width_factor,
            pad_height,pad_width);

    for (int batch = 0; batch < batches; ++batch) {
        for (int out_y = 0; out_y < output_height; ++out_y) {
            for (int out_x = 0; out_x < output_width; ++out_x) {
                for (int in_c = 0; in_c < input_depth; ++in_c) {
                    for (int m = 0; m < depth_multiplier; ++m) {
                        const int output_channel = m + in_c * depth_multiplier;
                        const int in_x0 = (out_x * stride_width) - pad_width;
                        const int in_y0 = (out_y * stride_height) - pad_height;
                        int32 acc = 0;
                        int8* filpt = (int8*)&filter_data[_Offset(filter_shape, 0, 0, 0, output_channel)];
                        for (int fil_y = 0; fil_y < filter_height; ++fil_y) {
                            for (int fil_x = 0; fil_x < filter_width; ++fil_x) {
                                const int in_x = in_x0 + dilation_width_factor * fil_x;
                                const int in_y = in_y0 + dilation_height_factor * fil_y;
                                int32 filter_val = *filpt;
                                filpt += filter_shape.Dims(3);
                                // Zero padding by omitting the areas outside the image.
                                const bool is_point_inside_image =
                                        (in_x >= 0) && (in_x < input_width) && (in_y >= 0) &&
                                        (in_y < input_height);
                                if (is_point_inside_image) {
                                    int32 input_val = input_data[_Offset(input_shape, batch, in_y,
                                            in_x, in_c)];
                                    //int32 filter_val = filter_data[_Offset(
                                    //    filter_shape, 0, fil_y, fil_x, output_channel)];
                                    // Accumulate with 32 bits accumulator.
                                    // In the nudging process during model quantization, we force
                                    // real value of 0.0 be represented by a quantized value. This
                                    // guarentees that the input_offset is a int8, even though it
                                    // is represented using int32.
                                    // int32 += int8 * (int8 - int8) so the highest value we can
                                    // get from each accumulation is [-127, 127] * ([-128, 127] -
                                    // [-128, 127]), which is [-32512, 32512]. log2(32512)
                                    // = 14.98, which means we can accumulate at least 2^16
                                    // multiplications without overflow. The accumulator is
                                    // applied to a filter so the accumulation logic will hold as
                                    // long as the filter size (fil_y * fil_x * in_c)
                                    // does not exceed 2^16, which is the case in all the models
                                    // we have seen so far.
                                    // TODO(jianlijianli): Add a check to make sure the
                                    // accumulator depth is smaller than 2^16.
                                    acc += filter_val * (input_val + input_offset);
                                }
                            }
                        }
                        if (bias_data) {
                            acc += bias_data[output_channel];
                        }
                        acc = _MultiplyByQuantizedMultiplier(
                                acc, output_multiplier[output_channel],
                                output_shift[output_channel]);
                        acc += output_offset;
                        acc = std::max(acc, output_activation_min);
                        acc = std::min(acc, output_activation_max);
                        output_data[_Offset(output_shape, batch, out_y, out_x,
                                output_channel)] = static_cast<int8_t>(acc);
                    }
                }
            }
        }
    }
}

inline void DepthwiseConv2(
        OpParams *params,
        const RuntimeShape& input_shape,  const float* input_data,
        const RuntimeShape& filter_shape, const float* filter_data,
        const RuntimeShape& bias_shape,   const float* bias_data,
        const RuntimeShape& output_shape, float* output_data) {

    const int stride_width = params->stride_width;
    const int stride_height = params->stride_height;
    const int dilation_width_factor = params->dilation_width_factor;
    const int dilation_height_factor = params->dilation_height_factor;
    const int pad_width = params->pad_width;
    const int pad_height = params->pad_height;
    const int depth_multiplier = params->depth_multiplier;
    const float output_activation_min = params->activation_min;
    const float output_activation_max = params->activation_max;
    TFLITE_DCHECK_EQ(input_shape.DimensionsCount(), 4);
    TFLITE_DCHECK_EQ(filter_shape.DimensionsCount(), 4);
    TFLITE_DCHECK_EQ(output_shape.DimensionsCount(), 4);

    const int batches = MatchingDim(input_shape, 0, output_shape, 0);
    const int output_depth = MatchingDim(filter_shape, 3, output_shape, 3);
    const int input_height = input_shape.Dims(1);
    const int input_width  = input_shape.Dims(2);
    const int input_depth  = input_shape.Dims(3);
    const int filter_height = filter_shape.Dims(1);
    const int filter_width  = filter_shape.Dims(2);
    const int output_height = output_shape.Dims(1);
    const int output_width  = output_shape.Dims(2);
    TFLITE_DCHECK_EQ(output_depth, input_depth * depth_multiplier);
    TFLITE_DCHECK_EQ(bias_shape.FlatSize(), output_depth);

    float *outpt = output_data;
    for (int b = 0; b < batches; ++b) {
        for (int out_y = 0; out_y < output_height; ++out_y) {
            const int in_y0 = (out_y * stride_height) - pad_height;
            for (int out_x = 0; out_x < output_width; ++out_x) {
                const int in_x0 = (out_x * stride_width) - pad_width;
                for (int in_c = 0; in_c < input_depth; ++in_c) {
                    for (int m = 0; m < depth_multiplier; m++) {
                        const int out_c = m + in_c * depth_multiplier;
                        //const int in_x0 = (out_x * stride_width) - pad_width;
                        //const int in_y0 = (out_y * stride_height) - pad_height;
                        float total = 0.f;
                        const float *filpt = &filter_data[_Offset(filter_shape, 0, 0, 0, out_c)];
                        for (int fil_y = 0; fil_y < filter_height; ++fil_y) {
                            const int in_y = in_y0 + dilation_height_factor * fil_y;
                            const int in_y_valid = (in_y >= 0) && (in_y < input_height);
                            const float* inpt = &input_data[_Offset(input_shape, b, in_y, 0, in_c)];
                            for (int fil_x = 0; fil_x < filter_width; ++fil_x) {
                                const int in_x = in_x0 + dilation_width_factor * fil_x;
                                //const int in_y = in_y0 + dilation_height_factor * fil_y;
                                // If the location is outside the bounds of the input image,
                                // use zero as a default value.
                                float filter_value = *filpt;
                                filpt += filter_shape.Dims(3);
                                if ((in_x >= 0) && (in_x < input_width) && (in_y_valid)) {
                                    //float input_value = input_data[_Offset(input_shape, b, in_y, in_x, in_c)];
                                    float input_value = inpt[in_x*input_depth];
                                    //float filter_value = filter_data[_Offset(filter_shape, 0, fil_y, fil_x, out_c)];
                                    total += (input_value * filter_value);
                                }
                            }
                        }
                        float bias_value = 0.0f;
                        if (bias_data) {
                            bias_value = bias_data[out_c];
                        }
                        //output_data[_Offset(output_shape, b, out_y, out_x, out_c)] =
                        *outpt++ = ActivationFunctionWithMinMax(total + bias_value, output_activation_min, output_activation_max);
                    }
                }
            }
        }
    }
}

void EvalFloat(OpParams *params,
        TfLiteTensor* input, TfLiteTensor* filter, TfLiteTensor* bias, TfLiteTensor* output) {
    if(params->optype == kTfLiteBuiltinConv2d)
        Conv2(params,
                GetTensorShape(input),  GetTensorData<float>(input),
                GetTensorShape(filter), GetTensorData<float>(filter),
                GetTensorShape(bias),   GetTensorData<float>(bias),
                GetTensorShape(output), GetTensorData<float>(output));
    else if(params->optype == kTfLiteBuiltinDepthwiseConv2d)
        DepthwiseConv2(params,
                GetTensorShape(input),  GetTensorData<float>(input),
                GetTensorShape(filter), GetTensorData<float>(filter),
                GetTensorShape(bias),   GetTensorData<float>(bias),
                GetTensorShape(output), GetTensorData<float>(output));

}
void EvalQuantize(OpParams *params,
        TfLiteTensor* input, TfLiteTensor* filter, TfLiteTensor* bias, TfLiteTensor* output) {
    if(params->optype == kTfLiteBuiltinConv2d)
        //Conv2quant(params, input, filter, bias, output);
        Conv3quant(0, params, input, filter, bias, output);
    else if(params->optype == kTfLiteBuiltinDepthwiseConv2d)
        //DepthwiseConv2quant(params, input, filter, bias, output);
        Conv3quant(1, params, input, filter, bias, output);
}
void EvalQuantizePerChannel(OpParams *params,
        TfLiteTensor* input, TfLiteTensor* filter, TfLiteTensor* bias, TfLiteTensor* output) {
    if(params->optype == kTfLiteBuiltinConv2d)
        Conv2quantPerChannel(params, input, filter, bias, output);
    else if(params->optype == kTfLiteBuiltinDepthwiseConv2d)
        DepthwiseConv2PerChannel(params, input, filter, bias, output);
}
const char *OpTypwName(uint32_t optype){
    switch(optype){
    case kTfLiteBuiltinConv2d:  return "Conv2d";
    case kTfLiteBuiltinDepthwiseConv2d: return "dwConv2d";
    default: return "Not support";
    }
}

void PrintIntvect(const char *m, const TfLiteIntArray* v) {
    fprintf(stderr,"%s",m);
    if (!v) {
        fprintf(stderr," (null)\n");
        return;
    }
    for (int k = 0; k < v->size; k++) {
        fprintf(stderr," %d", v->data[k]);
    }
    fprintf(stderr,"\n");
}
void PrintTensorSize(const char *s, TfLiteTensor *v)
{
    fprintf(stderr,"%s %7ld ", s, v->bytes);
    for(int i = 0; i < v->dims->size-1; i++)
        fprintf(stderr,"%3d ", v->dims->data[i+1]);
}
inline bool isExists(int x, TfLiteIntArray* a){
    for(int i = 0; i < a->size; i++){
        if(x == a->data[i]) return true;
    }
    return false;
}

#ifdef DEBUG
static bool debug = true;
#else
static bool debug = false;
#endif


// This is where the execution of the operations or whole graph happens.
// The class below has an empty implementation just as a guideline
// on the structure.
class MyDelegate {
public:
    // Returns true if my delegate can handle this type of op.
    static bool SupportedOp(const TfLiteRegistration* registration) {
        switch (registration->builtin_code) {
        case kTfLiteBuiltinConv2d:
        case kTfLiteBuiltinDepthwiseConv2d:
            return true;
        default:
            return false;
        }
    }
    // Any initialization code needed
    bool Init(TfLiteContext* context, const TfLiteDelegateParams *params) {
        cma_malloc_init();
        return true;
    }

    // Any preparation work needed (e.g. allocate buffers)
    TfLiteStatus Prepare(TfLiteContext* context, TfLiteNode* node) {
        OpData *opdata = (OpData*)node->delegate->data_;
        TfLiteDelegateParams *params = (TfLiteDelegateParams*)node->builtin_data;
        if(debug){
            PrintIntvect(" nodes_to_replace:", params->nodes_to_replace);
            PrintIntvect(" output tensor:",node->outputs);
        }
        int nalloc = 0;

        for(int i = 0; i < params->nodes_to_replace->size; i++){
            int node_id = params->nodes_to_replace->data[i];
            TfLiteTensor *input = &context->tensors[opdata->input->data[node_id]];
            TfLiteTensor *weight = &context->tensors[opdata->weight->data[node_id]];
            TfLiteTensor *bias = &context->tensors[opdata->bias->data[node_id]];
            TfLiteTensor *output = &context->tensors[opdata->output->data[node_id]];

            prepare_buffer_size(kTfaccOutput, output->bytes);
            prepare_buffer_size(kTfaccInput,  input->bytes);
            prepare_buffer_size(kTfaccFilter, weight->bytes);
            prepare_buffer_size(kTfaccBias,   bias->bytes);

            int isexout;
            //            if(GetTensorData<float>(output) == nullptr){
            if(output->data.raw == nullptr){
            //    output->data.raw = (char *)malloc(output->bytes);
                output->data.raw = (char *)cma_malloc(output->bytes);
                nalloc += output->bytes;
                if(debug){
                    isexout = isExists(opdata->output->data[node_id], node->outputs);
                    fprintf(stderr,"   %3d %c %3d %8ld %16p(%x) %s %s %s %s ",
                            node_id, isexout?'*':' ', opdata->output->data[node_id], output->bytes, output->data.raw, (uint32_t)cma_get_phy_addr(output->data.raw),
                                    TfLiteTypeGetName(input->type),TfLiteTypeGetName(weight->type),TfLiteTypeGetName(bias->type),TfLiteTypeGetName(output->type));
                    PrintIntvect("shape",output->dims);
                }
            }else{
                fprintf(stderr," prepare: output %p\n", output->data.raw);
            }
            if(debug){
                fprintf(stderr, "  %c %-8s ", isexout?'*':' ', OpTypwName(opdata->params[node_id].optype));
                PrintTensorSize(" i:", input);
                PrintTensorSize(" f:", weight);
                PrintTensorSize(" b:", bias);
                PrintTensorSize(" o:", output);
                fprintf(stderr,"\n");
            }
        }
        if(debug){
            //        cma_malloc_buffers();
            fprintf(stderr, " Prepare: alloc %d  ", nalloc);
            fprintf(stderr, " n_alloc:%ld\n", get_cma_malloc_size());
        }
        return kTfLiteOk;
    }

    // Actual running of the delegate subgraph.
    TfLiteStatus Invoke(TfLiteContext* context, TfLiteNode* node) {
        cma_malloc_buffers();
        //printf(" n_alloc:%ld\n", get_cma_malloc_size());
        OpData *opdata = (OpData*)node->delegate->data_;
        TfLiteDelegateParams *params = (TfLiteDelegateParams*)node->builtin_data;
        for(int i = 0; i < params->nodes_to_replace->size; i++){
            int node_id = params->nodes_to_replace->data[i];
            TfLiteTensor *input = &context->tensors[opdata->input->data[node_id]];
            TfLiteTensor *weight = &context->tensors[opdata->weight->data[node_id]];
            TfLiteTensor *bias = &context->tensors[opdata->bias->data[node_id]];
            TfLiteTensor *output = &context->tensors[opdata->output->data[node_id]];
            if(node_id == 0) n_stage = 0;
            if(0&&debug){
                int isexout = isExists(opdata->output->data[node_id], node->outputs);
                fprintf(stderr,"Invoke(%2d) %3d %50s\t%ld\t", node_id, opdata->input->data[node_id],
                        input->name, input->bytes);
                PrintIntvect("shape", input->dims);
                fprintf(stderr," weight    %3d %50s\t%ld\t", opdata->weight->data[node_id], weight->name,weight->bytes);
                PrintIntvect("shape", weight->dims);
                fprintf(stderr," bias      %3d %50s\t%ld\t", opdata->bias->data[node_id], bias->name,bias->bytes);
                PrintIntvect("shape", bias->dims);
                fprintf(stderr," out %c     %3d %50s\t%ld\t", isexout?'*':' ',opdata->output->data[node_id],
                        output->name, output->bytes);
                PrintIntvect("shape", output->dims);
            }
            if(output->type != kTfLiteFloat32){
                if(output->type == kTfLiteUInt8)
                    EvalQuantize(&opdata->params[node_id], input, weight, bias, output);
                else if(output->type == kTfLiteInt8)
                    EvalQuantizePerChannel(&opdata->params[node_id], input, weight, bias, output);
                else
                    TF_LITE_ENSURE_STATUS(kTfLiteError);
            }else{
                EvalFloat(&opdata->params[node_id], input, weight, bias, output);
            }
           // printf(" n_alloc:%ld\n", get_cma_malloc_size());
        }

        return kTfLiteOk;
    }
    // ... Add any other methods needed.
};

// Create the TfLiteRegistration for the Kernel node which will replace
// the subgraph in the main TfLite graph.
TfLiteRegistration GetMyDelegateNodeRegistration() {
    // This is the registration for the Delegate Node that gets added to
    // the TFLite graph instead of the subgraph it replaces.
    // It is treated as an OP node. But in our case
    // Init will initialize the delegate.
    // Invoke will run the delegate graph.
    // Prepare for preparing the delegate.
    // Free for any cleaning needed by the delegate.
    TfLiteRegistration kernel_registration;
    kernel_registration.builtin_code = kTfLiteBuiltinDelegate;
    kernel_registration.custom_name = "MyDelegate";
    kernel_registration.free = [](TfLiteContext* context, void* buffer) -> void {
        delete reinterpret_cast<MyDelegate*>(buffer);
    };
    kernel_registration.init = [](TfLiteContext* context, const char* buffer,
            size_t len) -> void* {
        // In the node init phase, initialize MyDelegate instance
        const TfLiteDelegateParams* delegate_params =
                reinterpret_cast<const TfLiteDelegateParams*>(buffer);
        MyDelegate* my_delegate = new MyDelegate;
        if (!my_delegate->Init(context, delegate_params)) {
            return nullptr;
        }
        return my_delegate;
    };
    kernel_registration.invoke = [](TfLiteContext* context,
            TfLiteNode* node) -> TfLiteStatus {
        MyDelegate* kernel = reinterpret_cast<MyDelegate*>(node->user_data);
        return kernel->Invoke(context, node);
    };
    kernel_registration.prepare = [](TfLiteContext* context,
            TfLiteNode* node) -> TfLiteStatus {
        MyDelegate* kernel = reinterpret_cast<MyDelegate*>(node->user_data);
        return kernel->Prepare(context, node);
    };

    return kernel_registration;
}

// TfLiteDelegate methods

TfLiteStatus DelegatePrepare(TfLiteContext* context, TfLiteDelegate* delegate) {
    // Claim all nodes that can be evaluated by the delegate and ask the
    // framework to update the graph with delegate kernel instead.
    std::vector<int> supported_nodes;
    TfLiteIntArray* plan;
    TF_LITE_ENSURE_STATUS(context->GetExecutionPlan(context, &plan));
    TfLiteNode* node;
    TfLiteRegistration* registration;

    OpData *opdata = OpDataArrayCreate(plan->size);

    for (int node_index : ::tflite::TfLiteIntArrayView(plan)) {
        TF_LITE_ENSURE_STATUS(context->GetNodeAndRegistration(
                context, node_index, &node, &registration));
        if (MyDelegate::SupportedOp(registration)) {
            
            opdata->input->data[node_index]  = node->inputs->data[0];
            opdata->weight->data[node_index] = node->inputs->data[1];
            opdata->bias->data[node_index]   = node->inputs->data[2];
            opdata->output->data[node_index] = node->outputs->data[0];

            OpParamsPrepare(context,
                    &context->tensors[node->inputs->data[0]],   // input
                    &context->tensors[node->inputs->data[1]],   // filter
                    &context->tensors[node->inputs->data[2]],   // bias
                    &context->tensors[node->outputs->data[0]],  // output
                    &opdata->params[node_index], node->builtin_data, registration->builtin_code);
            /*
            TfLiteConvParams* tfparm = (TfLiteConvParams*)node->builtin_data;
            fprintf(stderr,"DelegatePrepare %d %d %d\n",node_index, registration->builtin_code, tfparm->activation);

            PrintIntvect("  inputs: ",node->inputs);
            PrintIntvect("  outputs: ",node->outputs);
             */
            supported_nodes.push_back(node_index);
        }
    }
    delegate->data_ = opdata;
    TfLiteRegistration my_delegate_kernel_registration =
            GetMyDelegateNodeRegistration();

    // This call split the graphs into subgraphs, for subgraphs that can be
    // handled by the delegate, it will replace it with a
    // 'my_delegate_kernel_registration'
    TfLiteIntArray* supported_nodes_int_array =
            ::tflite::ConvertVectorToTfLiteIntArray(supported_nodes);
    //    PrintIntvect(" supported_nodes_int_array : ",supported_nodes_int_array);
    //    fprintf(stderr," data_: %p\n", delegate->data_);
    auto status = context->ReplaceNodeSubsetsWithDelegateKernels(
            context, my_delegate_kernel_registration,
            supported_nodes_int_array, delegate);
    TfLiteIntArrayFree(supported_nodes_int_array);
//    fprintf(stderr," ==== DelegatePrepare end.\n");
    return status;
}

void FreeBufferHandle(TfLiteContext* context, TfLiteDelegate* delegate,
        TfLiteBufferHandle* handle) {
    // Do any cleanups.
}

TfLiteStatus CopyToBufferHandle(TfLiteContext* context,
        TfLiteDelegate* delegate,
        TfLiteBufferHandle buffer_handle,
        TfLiteTensor* tensor) {
    fprintf(stderr,"CopyToBufferHandle\n");
    // Copies data from tensor to delegate buffer if needed.
    return kTfLiteOk;
}

TfLiteStatus CopyFromBufferHandle(TfLiteContext* context,
        TfLiteDelegate* delegate,
        TfLiteBufferHandle buffer_handle,
        TfLiteTensor* tensor) {
    fprintf(stderr,"CopyFromBufferHandle\n");
    // Copies the data from delegate buffer into the tensor raw memory.
    return kTfLiteOk;
}

// Caller takes ownership of the returned pointer.
TfLiteDelegate* CreateMyDelegate() {
    TfLiteDelegate* delegate = new TfLiteDelegate;

    delegate->data_ = nullptr;
    delegate->flags = kTfLiteDelegateFlagsNone;
    delegate->Prepare = &DelegatePrepare;
    // This cannot be null.
    delegate->CopyFromBufferHandle = &CopyFromBufferHandle;
    // This can be null.
    delegate->CopyToBufferHandle = &CopyToBufferHandle;
    // This can be null.
    delegate->FreeBufferHandle = &FreeBufferHandle;

    return delegate;
}

} // namespace tflite 

/*---
// To add the delegate you need to call

auto* my_delegate = CreateMyDelegate();
if (interpreter->ModifyGraphWithDelegate(my_delegate) !=
        kTfLiteOk) {
  // Handle error
} else {
  interpreter->Invoke();
}
...
// Don't forget to delete your delegate
delete my_delegate;

tensorflow/lite/python/interpreter.py
 """Python wrapper class to manage TfLiteDelegate objects.

  The shared library is expected to have two functions:
    TfLiteDelegate* tflite_plugin_create_delegate(
        char**, char**, size_t, void (*report_error)(const char *))
    void tflite_plugin_destroy_delegate(TfLiteDelegate*)

  The first one creates a delegate object. It may return NULL to indicate an
  error (with a suitable error message reported by calling report_error()).
  The second one destroys delegate object and must be called for every
  created delegate object. Passing NULL as argument value is allowed, i.e.

    tflite_plugin_destroy_delegate(tflite_plugin_create_delegate(...))

  always works.
  """

---*/

extern "C" {

TfLiteDelegate* tflite_plugin_create_delegate(
        char**, char**, size_t, void (*report_error)(const char *))
{
    auto* my_delegate = tflite::CreateMyDelegate();
    return my_delegate;
}

void tflite_plugin_destroy_delegate(TfLiteDelegate* my_delegate)
{
    delete my_delegate;
}

}

