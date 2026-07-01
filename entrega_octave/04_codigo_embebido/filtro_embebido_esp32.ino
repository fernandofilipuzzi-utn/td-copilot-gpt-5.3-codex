/*
  Filtro embebido de referencia para ESP32.
  Modo FIR o IIR por bandera USE_FIR.
  Senal de ejemplo: lectura ADC normalizada.
*/

#include <Arduino.h>

#define FS_HZ 1000
#define USE_FIR 1

#if USE_FIR
// FIR corto de referencia (pasa banda aproximado) para demo en MCU.
const int FIR_TAPS = 21;
const float fir_b[FIR_TAPS] = {
  -0.0032f, -0.0051f, -0.0069f, -0.0034f, 0.0103f,
  0.0358f, 0.0669f, 0.0932f, 0.1058f, 0.0991f,
  0.0731f,
  0.0991f, 0.1058f, 0.0932f, 0.0669f,
  0.0358f, 0.0103f, -0.0034f, -0.0069f, -0.0051f,
  -0.0032f
};
float fir_x[FIR_TAPS] = {0};
int fir_idx = 0;
#else
// IIR biquad cascada HP + LP (forma directa I).
const int B_LEN = 5;
const int A_LEN = 5;
const float iir_b[B_LEN] = {0.6325f, -1.2650f, 0.6325f, 0.0000f, 0.0000f};
const float iir_a[A_LEN] = {1.0000f, -1.1429f, 0.4128f, 0.0000f, 0.0000f};
float iir_x[B_LEN] = {0};
float iir_y[A_LEN] = {0};
#endif

const int ADC_PIN = 34;

float readSensorSample() {
  int raw = analogRead(ADC_PIN);
  float centered = (float)raw - 2048.0f;
  return centered / 2048.0f;
}

#if USE_FIR
float processFir(float x) {
  fir_x[fir_idx] = x;

  float y = 0.0f;
  int idx = fir_idx;
  for (int k = 0; k < FIR_TAPS; k++) {
    y += fir_b[k] * fir_x[idx];
    idx--;
    if (idx < 0) {
      idx = FIR_TAPS - 1;
    }
  }

  fir_idx++;
  if (fir_idx >= FIR_TAPS) {
    fir_idx = 0;
  }

  return y;
}
#else
float processIir(float x) {
  for (int i = B_LEN - 1; i > 0; i--) {
    iir_x[i] = iir_x[i - 1];
  }
  iir_x[0] = x;

  float y = 0.0f;
  for (int i = 0; i < B_LEN; i++) {
    y += iir_b[i] * iir_x[i];
  }
  for (int i = 1; i < A_LEN; i++) {
    y -= iir_a[i] * iir_y[i - 1];
  }

  for (int i = A_LEN - 1; i > 0; i--) {
    iir_y[i] = iir_y[i - 1];
  }
  iir_y[0] = y;

  return y;
}
#endif

void setup() {
  Serial.begin(115200);
  analogReadResolution(12);
}

void loop() {
  static uint32_t last_us = 0;
  uint32_t now = micros();
  const uint32_t period_us = 1000000UL / FS_HZ;

  if (now - last_us >= period_us) {
    last_us += period_us;

    float x = readSensorSample();

    float y = 0.0f;
#if USE_FIR
    y = processFir(x);
#else
    y = processIir(x);
#endif

    Serial.print(x, 6);
    Serial.print(',');
    Serial.println(y, 6);
  }
}
