// Lighting mode: uncomment to compute per-pixel sky or sun lighting.
//#define Realtime_Skylight
//#define Realtime_Sunlight
#define SKYLIGHT_LIVE_SAMPLES 16 // [4 6 9 12 16 24 32]

#define Based_Altitude 1.00// [0.00 0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00 1.01 1.02 1.03 1.04 1.05 1.06 1.07 1.08 1.09 1.10 1.11 1.12 1.13 1.14 1.15 1.16 1.17 1.18 1.19 1.20 1.21 1.22 1.23 1.24 1.25 1.26 1.27 1.28 1.29 1.30 1.31 1.32 1.33 1.34 1.35 1.36 1.37 1.38 1.39 1.40 1.41 1.42 1.43 1.44 1.45 1.46 1.47 1.48 1.49 1.50 1.51 1.52 1.53 1.54 1.55 1.56 1.57 1.58 1.59 1.60 1.61 1.62 1.63 1.64 1.65 1.66 1.67 1.68 1.69 1.70 1.71 1.72 1.73 1.74 1.75 1.76 1.77 1.78 1.79 1.80 1.81 1.82 1.83 1.84 1.85 1.86 1.87 1.88 1.89 1.90 1.91 1.92 1.93 1.94 1.95 1.96 1.97 1.98 1.99 2.00]
#define Auto_Expousre_Mode 0//[0 1]
#define Auto_Expousre
#define Expousre_Gain 0.0 // [-4.0 -3.0 -2.0 -1.9 -1.8 -1.7 -1.6 -1.5 -1.4 -1.3 -1.2 -1.1 -1.0 -0.9 -0.8 -0.7 -0.6 -0.5 -0.4 -0.3 -0.2 -0.1 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define PI 3.1415926535
#define PI 3.1415926535
#define TAU 6.283185307
#define DEG_TO_RAD 0.0174533
#define rotation 23.5 // [0.0 10.0 15.0 23.5 30.0 45.0 60.0]
#define Vignette
#define Bloom 
#define Bloom_Scatter 0.70//[0.01 0.02 0.03 0.04 0.05 0.06 0.07 0.08 0.09 0.10 0.11 0.12 0.13 0.14 0.15 0.16 0.17 0.18 0.19 0.20 0.21 0.22 0.23 0.24 0.25 0.26 0.27 0.28 0.29 0.30 0.31 0.32 0.33 0.34 0.35 0.36 0.37 0.38 0.39 0.40 0.41 0.42 0.43 0.44 0.45 0.46 0.47 0.48 0.49 0.50 0.51 0.52 0.53 0.54 0.55 0.56 0.57 0.58 0.59 0.60 0.61 0.62 0.63 0.64 0.65 0.66 0.67 0.68 0.69 0.70 0.71 0.72 0.73 0.74 0.75 0.76 0.77 0.78 0.79 0.80 0.81 0.82 0.83 0.84 0.85 0.86 0.87 0.88 0.89 0.90 0.91 0.92 0.93 0.94 0.95 0.96 0.97 0.98 0.99 1.00]
#define Sun_Bloom
#define Vignette_Type 1//[0 1]
#define AMBIENT_COEFFICIENT 0.1
// Grafun 0.175 settings edition. Defaults preserve the original expressions.
// Percent options use compile-time bypasses at 100 (1.0x).
#define SUN_SIZE 100 // [50 75 100 125 150 200 300 400] Scales disc, solid angle normalization .
#define SUN_BRIGHTNESS 100 // [25 50 75 100 125 150 175 200 250 300 400] Scales sunlight, sun disc and direct lighting; not blocklight or moonlight.
#define SUN_COLOR_R 100 // [10 25 50 75 100 125 150 175 200] Sun-only color multiplier; independent of the internal global light scale.
#define SUN_COLOR_G 100 // [10 25 50 75 100 125 150 175 200] Sun-only color multiplier; independent of the internal global light scale.
#define SUN_COLOR_B 100 // [10 25 50 75 100 125 150 175 200] Sun-only color multiplier; independent of the internal global light scale.
#define MOON_DISTANCE 100 // [25 35 50 65 75 85 100 125 150 200 300 400] Default distance is 59 x MC_r. Moves the center without resizing the radius. Does not attenuate environmental moonlight.
#define MOON_SIZE 100 // [50 75 100 125 150 175 200] Physical moon radius multiplier, independent of distance.
#define MOON_BRIGHTNESS 100 // [0 10 25 50 75 100 125 150 175 200 250 300] Changes the rendered moon surface, not environmental light or lens halo.
#define MOONLIGHT_BRIGHTNESS 100 // [0 10 25 50 75 100 125 150 175 200 250 300] Changes scene moonlight, independently of the visible moon.
#define MOON_ALBEDO_SCALE 0.27 // [0.05 0.10 0.15 0.20 0.25 0.27 0.30 0.35 0.40 0.50] Original moon albedo texture multiplier.
#define MOON_ALBEDO_OFFSET 0.08 // [0.00 0.02 0.04 0.06 0.08 0.10 0.12 0.15 0.20] Original moon albedo additive offset, not ambient night lighting.
#define STAR_BRIGHTNESS 0.875// [0.000 0.050 0.100 0.200 0.250 0.325 0.400 0.500 0.650 0.800 1.000] Visible star-map coefficient. Does not alter sun or moon discs.
#define SSR_MAX_STEPS 512 // [64 128 192 256 384 512 768 1024] Original SSR step limit; distance also depends on step size.
#define SSR_STEP_SIZE 0.5 // [0.125 0.25 0.375 0.5 0.75 1.0] Original world-space ray step, larger steps can miss thin geometry.
#define SSR_THICKNESS 0.5 // [0.125 0.25 0.375 0.5 0.75 1.0] Original geometry-distance intersection tolerance.
#define REFLECTION_BLUR 1.0 // [0.0 0.5 1.0 1.5 2.0] Original box-filter radius in pixels.
#define REFLECTION_STRENGTH 100 // [0 25 50 75 100 125 150 175 200] Scales reflection compositing for transparent and wet surfaces.
#define BLOCKLIGHT_STRENGTH 100 // [0 10 25 50 75 100 125 150 175 200 250 300] Scales block lights, hand light .
#define BLOCKLIGHT_COLOR_R 1.0 // [0.1 0.25 0.5 0.75 1.0 1.25 1.5] Original blocklight RGB component.
#define BLOCKLIGHT_COLOR_G 0.5 // [0.05 0.1 0.25 0.4 0.5 0.6 0.75 1.0] Original blocklight RGB component.
#define BLOCKLIGHT_COLOR_B 0.08 // [0.00 0.04 0.08 0.12 0.20 0.30 0.50 0.75 1.0] Original blocklight RGB component.
#define EXPOSURE_ADAPTATION 3 // [1 2 3 5 8 10 15 20 30 50 100] Per-frame adaptation weight, not seconds; default 0.03.
#define MANUAL_EXPOSURE_DIVISOR 0.05 // [0.005 0.01 0.02 0.03 0.05 0.075 0.10 0.15 0.20 0.30 0.50] Used only with auto exposure off. Lower means brighter.
#define AUTO_EXPOSURE_SCALE 2.0 // [0.5 0.75 1.0 1.5 2.0 2.5 3.0 4.0] Original multiplier applied to automatic exposure divisor.
#define BLOOM_STRENGTH 100 // [0 10 25 50 75 100 125 150 175 200 250 300] Bloom composite strength, independent of sun/moon lens halo.
#define BLOOM_THRESHOLD 1.0 // [0.25 0.50 0.75 1.0 1.25 1.50 2.0 3.0 4.0] Original per-channel threshold; special sun-disc injection is separate.
#define SUN_BLOOM_BOOST 25 // [0 1 2 5 10 15 20 25 35 50 75] Original sun-disc bloom injection, not radial lens halo.
#define SUN_HALO_INTENSITY 0.075 // [0.000 0.010 0.025 0.050 0.075 0.100 0.150 0.200] Radial sun halo strength; spikes are controlled separately.
#define MOON_HALO_INTENSITY 0.075 // [0.000 0.010 0.025 0.050 0.075 0.100 0.150 0.200] Radial moon halo, independent of moon surface and environmental light.
#define HALO_MIE_G 0.75 // [0.20 0.35 0.50 0.60 0.70 0.75 0.80 0.85 0.90] Controls lens halo peak and distribution, not a pure radius; separate from atmosphere.
#define SUN_SPIKE_INTENSITY 0.25 // [0.00 0.05 0.10 0.15 0.25 0.35 0.50 0.75 1.00] Zero removes sun spikes while retaining radial halo.
#define MOON_SPIKE_INTENSITY 0.25 // [0.00 0.05 0.10 0.15 0.25 0.35 0.50 0.75 1.00] Independent moon spike strength.
#define SPIKE_SHARPNESS 250 // [32 64 100 150 200 250 350 500 750 1000] Higher exponent narrows spikes; original directions are retained.
#define GHOST_INTENSITY 75 // [0 10 25 50 75 100 125 150] Original lens ghost multiplier. Zero disables ghosts, not halos.
#define GHOST_SCALE_R 0.11 // [0.05 0.07 0.09 0.1 0.11 0.13 0.15 0.20 0.25] Original per-channel ghost sampling scale; original sampling order is retained.
#define GHOST_SCALE_G 0.1 // [0.05 0.07 0.09 0.1 0.11 0.13 0.15 0.20 0.25] Original per-channel ghost sampling scale; original sampling order is retained.
#define GHOST_SCALE_B 0.09 // [0.05 0.07 0.09 0.1 0.11 0.13 0.15 0.20 0.25] Original per-channel ghost sampling scale; original sampling order is retained.
#define VIGNETTE_STRENGTH 100 // [0 10 25 50 75 100] Blends original vignette with no vignette; default retains original expression.
#define TONEMAP_GAIN 1.12 // [0.50 0.75 1.00 1.12 1.25 1.50 1.75 2.00] Original input gain; ACES matrices and fit remain unchanged.

#define FXAA_ENABLED // Enable the original FXAA pass.
#define TAA
