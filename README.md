# Plant-Disease-Detection-iOS-App
Plant Disease Detection iOS App using CNN

# Keras model to iOS CoreML model convertation Python code

``` python
from keras.models import load_model
import keras
import coremltools
import pickle

model = load_model('crop.h5') # Keras модель
lb = pickle.loads(open("label_transform.pkl", "rb").read()) # LabelBinarizer
class_labels = lb.classes_.tolist()

coreml_model = coremltools.converters.keras.convert(model,
	input_names="image",
	image_input_names="image",
	image_scale=1/255.0,
	class_labels=class_labels,
	is_bgr=True)
  
coreml_model.save("coreml_model.mlmodel")
```
