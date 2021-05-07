import cv2
import os

for dataset in os.listdir('dataset'):
  if not dataset.startswith('.'):
    datasetPath = os.path.join('dataset', dataset)
    for subdir in os.listdir(datasetPath):
      subpath = os.path.join(datasetPath, subdir)
      globalPath = os.path.join(subpath, 'global.png')
      localPath = os.path.join(subpath, 'local.png')
      indirectPath = os.path.join(subpath, 'indirect.png')

      globalImg = cv2.imread(globalPath, 0)
      localImg = cv2.imread(localPath, 0)

      indirect = cv2.absdiff(globalImg, localImg)
      cv2.imwrite(indirectPath, indirect)