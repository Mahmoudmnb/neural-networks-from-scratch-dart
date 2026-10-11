import 'dart:math';

/// Activation choices supported by the educational neural-network examples.
enum ActivationFunction { sigmoid, relu }

/// Backward-compatible access to the original short enum-style names.
class AF {
  static const sigFun = ActivationFunction.sigmoid;
  static const rlu = ActivationFunction.relu;
}

/// Sigmoid activation used by the original MLP and Elman implementations.
double sigmoidActivation(double value) {
  return 1 / (1 + pow(e, -value));
}

/// ReLU activation used when a layer selects [ActivationFunction.relu].
double reluActivation(double value) {
  return max(0, value);
}

/// Backward-compatible wrapper for the original misspelled/short function name.
double sigFun(double value) => sigmoidActivation(value);

/// Backward-compatible wrapper for the original ReLU helper name.
double rluFun(double value) => reluActivation(value);

double Function(double) activationFor(ActivationFunction activationFunction) {
  switch (activationFunction) {
    case ActivationFunction.sigmoid:
      return sigmoidActivation;
    case ActivationFunction.relu:
      return reluActivation;
  }
}
