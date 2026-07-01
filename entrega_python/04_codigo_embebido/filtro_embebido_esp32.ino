/*
  filtro_embebido_esp32.ino
  Illustrative implementation for ESP32 using FIR and IIR options.
  Coefficients are placeholders from the Python design stage.
*/

#include <Arduino.h>

static const int FIR_TAPS = 11;
static const float fir_b[FIR_TAPS] = {
  -0.0112f, -0.0215f, 0.0000f, 0.0908f, 0.2163f,
   0.3000f,
   0.2163f, 0.0908f, 0.0000f, -0.0215f, -0.0112f
};

static const float iir_b[5] = {0.2015f, 0.0000f, -0.4030f, 0.0000f, 0.2015f};
static const float iir_a[5] = {1.0000f, -1.5560f, 0.7520f, -0.0840f, 0.0180f};

float fir_x[FIR_TAPS] = {0.0f};
float iir_x[5] = {0.0f};
float iir_y[5] = {0.0f};

float apply_fir(float xn) {
  for (int i = FIR_TAPS - 1; i > 0; --i) {
    fir_x[i] = fir_x[i - 1];
  }
  fir_x[0] = xn;

  float y = 0.0f;
  for (int i = 0; i < FIR_TAPS; ++i) {
    y += fir_b[i] * fir_x[i];
  }
  return y;
}

float apply_iir(float xn) {
  for (int i = 4; i > 0; --i) {
    iir_x[i] = iir_x[i - 1];
    iir_y[i] = iir_y[i - 1];
  }
  iir_x[0] = xn;

  float y = 0.0f;
  y += iir_b[0] * iir_x[0] + iir_b[1] * iir_x[1] + iir_b[2] * iir_x[2];
  y += iir_b[3] * iir_x[3] + iir_b[4] * iir_x[4];
  y -= iir_a[1] * iir_y[1] + iir_a[2] * iir_y[2] + iir_a[3] * iir_y[3] + iir_a[4] * iir_y[4];

  iir_y[0] = y;
  return y;
}

void setup() {
  Serial.begin(115200);
}

void loop() {
  float sensor_sample = analogRead(34) / 4095.0f;

  // Switch here based on the recommendation.
  float y = apply_iir(sensor_sample);

  Serial.println(y, 6);
  delay(1); // Approx 1 kHz loop target
}
