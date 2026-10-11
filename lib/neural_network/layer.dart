import 'activation_functions.dart';
import 'neuron.dart';

/// Layer definition and runtime neuron container.
class Layer {
  int numOfNeurons;
  List<Node> neurons = [];
  ActivationFunction activationFunction;

  Layer({required this.numOfNeurons, required this.activationFunction});
}
