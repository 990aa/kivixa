// Texture brush fragment shader
// Version 460 core for Flutter fragment shaders
#version 460 core

#include <flutter/runtime_effect.glsl>

// Uniforms
uniform vec2 uSize;              // Brush size (width, height)
uniform vec4 uColor;             // Brush color (rgba, 0.0-1.0)
uniform float uOpacity;          // Brush opacity (0.0-1.0)
uniform sampler2D uBrushTexture; // Brush texture

// Output
out vec4 fragColor;

void main() {
  // Get normalized coordinates (0.0-1.0)
  vec2 uv = FlutterFragCoord().xy / uSize;
  
  // Sample the brush texture
  vec4 texColor = texture(uBrushTexture, uv);
  
  // Apply color tinting (use red channel as mask)
  vec4 tintedColor = uColor * texColor.r;
  
  // Apply opacity
  float finalAlpha = tintedColor.a * uOpacity;
  
  // Output final color
  fragColor = vec4(tintedColor.rgb * uOpacity, finalAlpha);
}
