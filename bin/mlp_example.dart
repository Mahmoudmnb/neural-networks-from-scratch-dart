import 'dart:io';

import 'package:csv/csv.dart';

import '../lib/data/dataset_utils.dart';
import '../lib/data/dictionary.dart';
import '../lib/neural_network/activation_functions.dart';
import '../lib/neural_network/layer.dart';
import '../lib/neural_network/mlp.dart';

const breastCancerCsvPath = 'data/Breast_Cancer.csv';
const trainDatasetPath = 'artifacts/prepared_datasets/train_ds.ds.mnb';
const testDatasetPath = 'artifacts/prepared_datasets/test_ds.ds.mnb';
const mlpWeightsPath = 'artifacts/weights/30_neuron.w.mnb';

void main(List<String> args) {
  final input = File(breastCancerCsvPath).readAsStringSync();
  final rows = const CsvToListConverter().convert(input);
  final titles = rows.first;
  rows.removeAt(0);
  final dic = Dictionary(data: rows, titles: titles, withNormalize: true);

  // To regenerate prepared datasets from the CSV, uncomment this block.
  // The serialization format is the same `.mnb` text format used originally.
  // final preparedDataset = prepareDataset(titles: titles, data: rows, dic: dic);
  // final trainInputs = preparedDataset['train_ds']!;
  // final trainLabels = preparedDataset['train_labels']!;
  // final testInputs = preparedDataset['test_ds']!;
  // final testLabels = preparedDataset['test_labels']!;
  // saveDataset(path: trainDatasetPath, data: trainInputs, labels: trainLabels);
  // saveDataset(path: testDatasetPath, data: testInputs, labels: testLabels);

  final trainDataset = loadDataset(path: trainDatasetPath);
  final testDataset = loadDataset(path: testDatasetPath);
  final trainInputs = trainDataset['data'] as List<List<double>>;
  final trainLabels = trainDataset['labels'] as List<double>;
  final testInputs = testDataset['data'] as List<List<double>>;
  final testLabels = testDataset['labels'] as List<double>;
  const epoch = 10;
  final nn = MLP(
    trainLabels: trainLabels,
    trainInputs: trainInputs,
    testInputs: testInputs,
    testLabels: testLabels,
    layers: [
      Layer(numOfNeurons: 30, activationFunction: ActivationFunction.sigmoid),
      Layer(numOfNeurons: 1, activationFunction: ActivationFunction.sigmoid),
    ],
    lr: 0.01,
    epoch: epoch,
  );
  nn.loadWeights(mlpWeightsPath);
  nn.train(
    callBack: (e) {
      // if (e > 3 && e % (epoch / 3).floor() == 0) {
      //   nn.lr /= 10;
      // }
      nn.saveWeights(mlpWeightsPath);
    },
  );

  for (var i = 0; i < 100; i++) {
    var output = nn.modelOutput(data: testInputs[i]).first;
    output = output >= 0.5 ? 1 : 0;
    final actual = testLabels[i];
    print(
      '============================================================================',
    );
    print(
      'actual: ${dic.fromToken(title: titles.last, token: output)}',
    );
    print('desired: ${dic.fromToken(title: titles.last, token: actual)}');
  }
}
