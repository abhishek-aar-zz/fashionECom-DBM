from PIL import Image
import numpy as np

im = Image.open('x.png')
im = im.convert('RGBA')

data = np.array(im)   # "data" is a height x width x 4 numpy array
red, green, blue, alpha = data.T # Temporarily unpack the bands for readability

# Replace white with red... (leaves alpha values alone...)
white_areas = (red == 0) & (blue == 0) & (green == 0)
data[..., :-1][white_areas.T] = (68,68,76) # Transpose back needed

im2 = Image.fromarray(data)
im2.save('xx.png')