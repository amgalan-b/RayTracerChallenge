# RayTracerChallenge
![preview_soft_shadows](https://github.com/amgalan-b/RayTracerChallenge/assets/11941449/2348ec3f-cf8d-4375-b06a-f27cdd6ee566)

Swift implementation for the book [http://raytracerchallenge.com](http://raytracerchallenge.com/).

If you have even a remote interest in 3D graphics or simply enjoy programming and want a fun challenge, I wholeheartedly recommend this book.
You will write a complete ray tracer from scratch using your favorite language, without relying on any libraries or frameworks.

You can recreate the image above using the following command:

```bash
swift run -c release ray-tracer Scenes/shadow_glamour_shot.yaml --output preview.ppm
```

The output is in `ppm` format, which is natively supported by macOS Preview. However, if you prefer the output in `jpeg` or `png` format, you can use `magick`:

```bash
convert input.ppm output.png

# you can also pipe directly to magick
ray-tracer Scenes/cover.yaml --type scene | convert ppm:- output.png
```
![preview_skybox](https://github.com/amgalan-b/RayTracerChallenge/assets/11941449/3189a985-3fa1-4ac0-8c29-be0578c2e3fa)
There are many other example scenes in `Scenes/`. For this image, use the following command:
```bash
ray-tracer Scenes/skybox.yaml --output preview.ppm --width 1200 --height 600
```
## Unit Tests
If you encounter any errors, running unit tests might help you find a solution:
```
swift test
swift test -c release
```
## Usage
```
USAGE: ray-tracer <input> [--type <type>] [--output <output>] [--width <width>] [--height <height>]

ARGUMENTS:
  <input>                 OBJ file or YAML scene location. Use - to read from stdin.

OPTIONS:
  --type <type>           Input file type. (default: scene)
  -o, --output <output>   Output PPM file location. Prints to stdout by default.
  --width <width>         Image width.
  --height <height>       Image height.
  -h, --help              Show help information.
```
