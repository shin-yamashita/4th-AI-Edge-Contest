#!/usr/bin/env python3
# coding: utf-8
# Inference Segmentation
#

import time
import argparse
import re
import cv2
from   PIL import Image
import numpy as np
import os
import os.path as osp
import sys
import select
import tty
import termios
import tflite_runtime.interpreter as tflite

def iskbhit():
    return select.select([sys.stdin], [], [], 0) == ([sys.stdin], [], [])

img_path = './'

# Path to tflite graph
parser = argparse.ArgumentParser(description='infer segmentation')
parser.add_argument('-i', '--input',  default=img_path+'/images', help="Input file dir")
parser.add_argument('-o', '--output', default=img_path+'/infer_images', help="Output file dir")
parser.add_argument('-a', '--annotation',  default=img_path+'/seg_train_annotations', help="annotation file dir")
parser.add_argument('-c', '--cpu',      action='store_true', default=False, help="disable delegate")
parser.add_argument('-q', '--quantize', default=True,  action='store_true', help="uint8 model")
parser.add_argument('-I', '--I8',       default=False, action='store_true', help="int8 model")
parser.add_argument('-f', '--float',    default=False, action='store_true', help="float model (cpu exec)")
parser.add_argument('--eval',  default=False, action='store_true', help="eval iou")
parser.add_argument('--test',  default=False, action='store_true', help="measure infer time")

args = parser.parse_args()

### Prepare TFlite interpreter
if args.float:
  model = './tflite_graphs/seg_graph_f.tflite'
elif args.I8:
  model = './tflite_graphs/seg_graph_i8.tflite'
else:
  model = './tflite_graphs/seg_graph_q.tflite'

print("tflite model: ", model)

slib = "./tflite_delegate/libmydelegate.so.1"

if(args.cpu or args.float):
  interpreter = tflite.Interpreter(model_path=model)
else:
  interpreter = tflite.Interpreter(model_path=model, experimental_delegates=[tflite.load_delegate(slib)] )

interpreter.allocate_tensors()

# Get input and output tensors.
input_details  = interpreter.get_input_details()
output_details = interpreter.get_output_details()

category = [
  ['background', (0,0,0)],
  ['Lane', (69,47,142)],
  ['Signal', (255,255,0)],
  ['Pedestrian', (255,0,0)],
  ['Car', (0,0,255)],
 ]
palette = [
  0,0,0,
  69,47,142,
  255,255,0,
  255,0,0,
  0,0,255
 ]

colormap = np.zeros((256, 3), dtype=int)
for i, cat in enumerate(category):
  colormap[i] = cat[1]

def label_to_color_image(label):
  return colormap[label].astype(np.uint8)

def make_color2class_lut():
#  LUT = np.zeros((256, 1), np.uint8)
  LUT = np.full((256, 1), 255, np.uint8)
  img = np.zeros((21, 1, 3), np.uint8)
  for x,[k,v] in enumerate(category):
    img[x,0] = v
  img = cv2.cvtColor(img, cv2.COLOR_RGB2GRAY)
  for i, g in enumerate(img):
    LUT[g] = i
  return LUT

def convert_color_to_class(img_bgr):
  LUT = make_color2class_lut()
  img_gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
  img_idx  = cv2.LUT(img_gray, LUT)
  return img_idx

def iou_calc(pred, anno):
  anno = convert_color_to_class(anno)
  tot = pred.shape[0] * pred.shape[1] 	# total pixel
  miou = 0.0
  nc = 0
  eval = []
  for cat in range(1,5):	# 1:lane 2:signal 3:pedestrian 4:car
    pr = np.zeros(pred.shape, dtype=np.uint8)
    gt = np.zeros(anno.shape, dtype=np.uint8)
    pr[pred==cat] = 1
    gt[anno==cat] = 1
    inter = pr & gt
    union = pr | gt
    nt = np.sum(gt)
    ni = np.sum(inter)
    nu = np.sum(union)
    iou = ni*100.0/nu if nt>0 else 0.0
#    print("%10s tot: %d  true:%d  union: %d  inter: %d  iou: %5.2f"%(category[cat][0], tot, nt, nd, ni, iou))
    print("%10s %5.2f "%(category[cat][0], iou), end='')
    if(nt > 0):
      miou += iou
      nc += 1
    eval.append([cat,nt,nu,ni,iou])
  miou /= nc
  print(" miou: %5.2f"%(miou), end='')
  return miou, eval


def run_inference_for_single_image(image):
  # Run inference
  # image range : 0.0 to 256.0

  if(args.float):
    interpreter.set_tensor(input_details[0]['index'], np.float32(image)/128.0-1.0)
  else:
    interpreter.set_tensor(input_details[0]['index'], np.uint8(image))

  interpreter.invoke()

  # infer out
  segments = interpreter.get_tensor(output_details[0]['index'])[0]
#  print("segments:",segments.shape, np.max(segments))

  return segments.astype(np.uint8)

if __name__ == '__main__':

  size = (1025, 513)	# cv2 W,H

  images = args.input
  if(images.endswith('.jpg')): imlist = [images]
  else:
    imlist = [osp.join(osp.realpath('.'), images, img) for img in os.listdir(images) if os.path.splitext(img)[1].lower() == '.jpg']
  primgpath = args.output

  mIOU = 0.0
  nev = 0
  ntest = 0
  tpre = 0.0
  tinfer = 0.0
  tpost = 0.0

  old_settings = termios.tcgetattr(sys.stdin)
  try:
    tty.setcbreak(sys.stdin.fileno())

    for image_path in imlist:
      if(iskbhit()):
        c = sys.stdin.read(1)
        if(c == '\x1b'): break

      file = image_path.split('/')[-1]
      if not args.test:
        print("input:", image_path)
        anno = cv2.imread(osp.join(args.annotation, file.replace(".jpg",".png")))
        ano_bgr = None
        if(not anno is None):
          print("anno :", osp.join(args.annotation, file.replace(".jpg",".png")))
          anno = anno[68:1036,:]  # 上下計12% crop
          ano_bgr = cv2.resize(anno, size, interpolation = cv2.INTER_NEAREST)

      img = cv2.imread(image_path)
      height,width,_ = img.shape[:3]
      blk_top = np.zeros((68, width), dtype=np.uint8)
      blk_btm = np.zeros((height-68-968, width), dtype=np.uint8)
#      print("input:", img.shape)

      t0 = time.time()
      img = img[68:1036,:]  # 上下計12% crop
      img_bgr = cv2.resize(img, size)

      # convert bgr to rgb
      image_np = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
      image_np_expanded = np.expand_dims(image_np, axis=0)	# 1,,,3

      t1 = time.time()
      segments = run_inference_for_single_image(image_np_expanded)	#, detection_graph)
      t2 = time.time()


      if not args.test:
        if(not ano_bgr is None):
          iou, eval = iou_calc(segments, ano_bgr)
          mIOU += iou
          nev += 1
          print("  mIOU:%g"%(mIOU/nev))

      if(args.eval or args.test):
          basename = os.path.splitext(os.path.basename(image_path))[0]
          primg_path = primgpath + '/' + basename + ".png"

          segimg = cv2.resize(segments, (width,height), interpolation = cv2.INTER_NEAREST)
          segimg_blk = np.concatenate([blk_top, segimg, blk_btm])
          img = Image.fromarray(segimg_blk, mode="P")
          img.putpalette(palette)
            
          t3 = time.time()
          img.save(primg_path)

          print("infer:", primg_path)
          # measure inference time
          ntest  += 1
          tpre   += (t1 - t0) * 1e3
          tinfer += (t2 - t1) * 1e3
          tpost  += (t3 - t2) * 1e3
          print(" pre: %5.2f  infer: %5.2f  post: %5.2f total: %5.2fms / %d"%(tpre/ntest, tinfer/ntest, tpost/ntest, (tpre+tinfer+tpost)/ntest, ntest))

      else:
          segimg = label_to_color_image(segments)	# RGB label image
          sh = int(600 * height / width)
          if(not ano_bgr is None):
            img2 = cv2.hconcat([img_bgr, cv2.cvtColor(segimg,cv2.COLOR_RGB2BGR), ano_bgr])
            cv2.imshow('segmentation result', cv2.resize(img2, (600*3,sh)))
          else:
            img2 = cv2.hconcat([img_bgr, cv2.cvtColor(segimg,cv2.COLOR_RGB2BGR)])
            cv2.imshow('segmentation result', cv2.resize(img2, (600*2,sh)))

          key = cv2.waitKey(0)
          if key == 27: # when ESC key is pressed break
            cv2.destroyAllWindows()
            break

  finally:
    termios.tcsetattr(sys.stdin, termios.TCSADRAIN, old_settings)



