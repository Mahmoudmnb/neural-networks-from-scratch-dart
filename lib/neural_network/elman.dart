import 'dart:io';
import 'dart:math';

import 'activation_functions.dart';
import 'layer.dart';
import 'neuron.dart';

/// Elman recurrent network using manually managed context inputs.
class Elman {
  List<Layer> layers;
  List<List<double>> trainInputs;
  List<double> trainLabels;
  List<List<double>>? testInputs;
  List<double>? testLabels;
  double lr;
  int epoch;
  int step;

  Elman({
    required this.step,
    required this.layers,
    required this.trainInputs,
    required this.trainLabels,
    required this.lr,
    required this.epoch,
    this.testInputs,
    this.testLabels,
  }) : assert(trainInputs.length == trainLabels.length && layers.isNotEmpty) {
    layers.insert(
      0,
      Layer(
        numOfNeurons:
            trainInputs.first.length + layers[layers.length - 2].numOfNeurons,
        activationFunction: ActivationFunction.sigmoid,
      ),
    );
    for (var layerIndex = 0; layerIndex < layers.length; layerIndex++) {
      final layer = layers[layerIndex];
      final nodes = <Node>[];
      if (layerIndex == 0) {
        for (var i = 0; i < trainInputs.first.length; i++) {
          nodes.add(InputNeuron(input: trainInputs.first[i]));
        }
        for (var i = 0; i < layers[layers.length - 2].numOfNeurons; i++) {
          nodes.add(InputNeuron(input: 1));
        }
        layer.neurons = nodes;
        continue;
      }
      final activation = activationFor(layer.activationFunction);
      for (var neuronIndex = 0;
          neuronIndex < layer.numOfNeurons;
          neuronIndex++) {
        nodes.add(
          Neuron(
            inputs: layers[layerIndex - 1].neurons,
            activationFunction: activation,
          ),
        );
      }
      layer.neurons = nodes;
    }
  }

  double feedForward({required int neuronNumber, required int layerIndex}) {
    return layers[layerIndex].neurons[neuronNumber].output;
  }

  /// Feeds a time window and copies the hidden layer output into context inputs.
  void feedInput(List<List> data) {
    for (var s = 0; s < data.length; s++) {
      var index = data[s].length;
      final hiddenLayerIndex = layers.length - 2;
      final inputLayer = layers.first;
      for (var i = 0; i < layers[hiddenLayerIndex].numOfNeurons; i++) {
        final out = layers[hiddenLayerIndex].neurons[i].output;
        (inputLayer.neurons[index] as InputNeuron).input = out;
        index++;
      }
      for (var i = 0; i < data[s].length; i++) {
        (inputLayer.neurons[i] as InputNeuron).input = data[s][i];
      }
    }
  }

  /// Computes deltas and updates weights using the original Elman training flow.
  void backpropagation(int batchIndex) {
    for (var i = 1; i < layers.length; i++) {
      for (var j = 0; j < layers[i].numOfNeurons; j++) {
        (layers[i].neurons[j] as Neuron).d = 0;
      }
    }

    final outputLayer = layers.last;
    for (var i = 0; i < outputLayer.numOfNeurons; i++) {
      final loss = getOutputLayerLoss(batchIndex, i);
      final neuronOutput =
          feedForward(neuronNumber: i, layerIndex: layers.length - 1);
      final d = neuronOutput * (1 - neuronOutput) * loss;
      (outputLayer.neurons[i] as Neuron).d = d;
    }

    if (layers.length > 2) {
      for (var i = layers.length - 1; i > 1; i--) {
        for (var j = 0; j < layers[i].numOfNeurons; j++) {
          final currentNeuron = layers[i].neurons[j] as Neuron;
          final neuronInputs = currentNeuron.inputs;
          for (var k = 0; k < neuronInputs.length; k++) {
            final neuron = neuronInputs[k] as Neuron;
            neuron.d += currentNeuron.d * currentNeuron.weights[k];
          }
        }
        final firstNeuron = layers[i].neurons.first as Neuron;
        for (var l = 0; l < firstNeuron.inputs.length; l++) {
          final neuron = firstNeuron.inputs[l] as Neuron;
          neuron.d *= neuron.output * (1 - neuron.output);
        }
      }
    }

    for (var i = layers.length - 1; i > 0; i--) {
      final currentLayer = layers[i];
      for (var j = 0; j < currentLayer.numOfNeurons; j++) {
        final currentNeuron = currentLayer.neurons[j] as Neuron;
        for (var k = 0; k < currentNeuron.weights.length; k++) {
          currentNeuron.weights[k] +=
              lr * currentNeuron.inputs[k].output * currentNeuron.d;
        }
        currentNeuron.biasWeight += lr * currentNeuron.bias * currentNeuron.d;
      }
    }
  }

  double getOutputLayerLoss(int batchIndex, int neuronNumber) {
    final actualOutput =
        feedForward(neuronNumber: neuronNumber, layerIndex: layers.length - 1);
    return trainLabels[batchIndex] - actualOutput;
  }

  List<double> modelOutput() {
    final output = <double>[];
    for (var i = 0; i < layers.last.numOfNeurons; i++) {
      final value = feedForward(layerIndex: layers.length - 1, neuronNumber: i);
      output.add(value);
    }
    return output;
  }

  /// Trains on sliding windows of length [step], preserving the original
  /// recurrent-state and accuracy calculations.
  void train({Function(int epoch)? callBack}) {
    for (var e = 0; e < epoch; e++) {
      var trainTotalLoss = 0.0;
      var trainCorrect = 0;
      var testTotalLoss = 0.0;
      var testCorrect = 0;

      for (var i = 0; i < trainInputs.length - step; i++) {
        final batch = <List>[];
        for (var s = i; s < i + step; s++) {
          batch.add(trainInputs[s]);
        }
        feedInput(batch);
        backpropagation(i + step - 1);
        final output = modelOutput().first;
        final actual = trainLabels[i + step - 1];
        trainTotalLoss += pow(actual - output, 2);
        if ((output - actual).abs() < 0.001) {
          trainCorrect++;
        }
      }
      trainTotalLoss /= trainInputs.length;
      final trainAccuracy = trainCorrect / trainInputs.length;
      var resultText =
          'Epoch $e: trainLoss = $trainTotalLoss, trainAccuracy = $trainAccuracy';

      if (testInputs != null && testLabels != null) {
        for (var i = 0; i < testInputs!.length - step; i++) {
          final batch = <List>[];
          for (var s = i; s < i + step; s++) {
            batch.add(testInputs![s]);
          }
          feedInput(batch);
          final output = modelOutput().first;
          final actual = testLabels![i + step - 1];
          testTotalLoss += pow(actual - output, 2);
          if ((output - actual).abs() < 0.001) {
            testCorrect++;
          }
        }
        testTotalLoss /= testInputs!.length;
        final testAccuracy = testCorrect / testInputs!.length;
        resultText +=
            '      |      testLoss = $testTotalLoss, testAccuracy = $testAccuracy';
      }
      print(resultText);
      if (callBack != null) {
        callBack(e);
      }
    }
  }

  /// Persists weights in the original tab/newline-separated `.mnb` format.
  void saveWeights(String path) {
    var text = '';
    for (var l = 1; l < layers.length; l++) {
      for (var n = 0; n < layers[l].numOfNeurons; n++) {
        for (var i = 0; i < layers[l].neurons[n].weights.length; i++) {
          text += '${layers[l].neurons[n].weights[i]} ';
        }
        text += (layers[l].neurons[n] as Neuron).biasWeight.toString();
        if (n < layers[l].numOfNeurons - 1) {
          text += '\t';
        }
      }
      if (l < layers.length - 1) {
        text += '\n';
      }
    }
    File(path).writeAsStringSync(text);
  }

  /// Backward-compatible wrapper for the original misspelled method name.
  void saveWights(String path) => saveWeights(path);

  void loadWeights(String path) {
    final text = File(path).readAsStringSync();
    final layerStrings = text.trim().split('\n');
    for (var l = 1; l < layers.length; l++) {
      if (l - 1 >= layerStrings.length) {
        throw Exception(
            'Mismatch in saved layers and current model structure.');
      }
      final neuronStrings = layerStrings[l - 1].split('\t');
      for (var n = 0; n < layers[l].numOfNeurons; n++) {
        if (n >= neuronStrings.length) {
          throw Exception(
            'Mismatch in saved neurons and model structure in layer $l.',
          );
        }
        final weightStrings = neuronStrings[n].trim().split(' ');
        final neuron = layers[l].neurons[n] as Neuron;
        if (weightStrings.length != neuron.weights.length + 1) {
          throw Exception(
            'Mismatch in number of weights for neuron $n in layer $l. '
            'Expected ${neuron.weights.length + 1}, found ${weightStrings.length}.',
          );
        }
        for (var w = 0; w < neuron.weights.length; w++) {
          neuron.weights[w] = double.parse(weightStrings[w]);
        }
        neuron.biasWeight = double.parse(weightStrings.last);
      }
    }
  }
}
