import cv2
import os

for dataset in os.listdir('dataset'):
  if not dataset.startswith('.'):
    datasetPath = os.path.join(dir, dataset)
    for subdir in os.listdir(datasetPath):
      subpath = os.path.join(datasetPath, subdir)
      globalPath = os.path.join(subpath, 'global.png')
      localPath = os.path.join(subpath, 'local.png')
      indirectPath = os.path.join(subpath, 'indirect.png')

      indirectImg = cv2.imread(indirectPath, 0)
      localImg = cv2.imread(localPath, 0)

      globalImg = cv2.add(indirectImg, localImg)
      cv2.imwrite(globalPath, globalImg)