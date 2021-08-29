import cv2
import os

DATASET_FOLDER = "diffuse"

for dataset in os.listdir(DATASET_FOLDER):
    if not dataset.startswith("."):
        datasetPath = os.path.join(DATASET_FOLDER, dataset)
        for subdir in os.listdir(datasetPath):
            subpath = os.path.join(datasetPath, subdir)
            globalPath = os.path.join(subpath, "globalCheck.png")
            localPath = os.path.join(subpath, "local.png")
            indirectPath = os.path.join(subpath, "indirect.png")

            indirectImg = cv2.imread(indirectPath)
            localImg = cv2.imread(localPath)

            globalImg = cv2.add(indirectImg, localImg)

            cv2.imwrite(globalPath, globalImg)
