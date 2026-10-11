import 'dart:math';

/// Common interface for input nodes and trainable neurons.
abstract class Node {
  double get output => 0;

  List<double> weights = [];
}

/// Trainable neuron with one weight per input node and a separate bias weight.
class Neuron extends Node {
  List<Node> inputs;
  @override
  List<double> weights = [];
  double bias = 1;
  double biasWeight = 1;

  /// Backpropagated delta/error term used during weight updates.
  double d = 0;

  double Function(double) activationFunction;

  Neuron({required this.inputs, required this.activationFunction}) {
    final min = -2.4 / inputs.length;
    final max = 2.4 / inputs.length;
    final random = Random();
    biasWeight = min + (max - min) * random.nextDouble();
    for (final _ in inputs) {
      final randomDouble = min + (max - min) * random.nextDouble();
      weights.add(randomDouble);
    }
  }

  @override
  double get output {
    var sum = 0.0;
    for (var i = 0; i < inputs.length; i++) {
      sum += inputs[i].output * weights[i];
    }
    sum += bias * biasWeight;
    return activationFunction(sum);
  }
}

/// Input node whose output is assigned directly from a dataset row.
class InputNeuron extends Node {
  double input;

  InputNeuron({required this.input});

  @override
  double get output => input;
}
