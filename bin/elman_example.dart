import 'dart:io';

import 'package:csv/csv.dart';

import '../lib/data/dataset_utils.dart';
import '../lib/data/dictionary.dart';
import '../lib/neural_network/activation_functions.dart';
import '../lib/neural_network/elman.dart';
import '../lib/neural_network/layer.dart';

const netflixCsvPath = 'data/NetFlix.csv';
const elmanTrainDatasetPath =
    'artifacts/prepared_datasets/elman_train_ds.ds.mnb';
const elmanTestDatasetPath = 'artifacts/prepared_datasets/elman_test_ds.ds.mnb';
const elmanWeightsPath = 'artifacts/weights/elman_20_neuron.w.mnb';

void main(List<String> args) {
  final input = File(netflixCsvPath).readAsStringSync();
  final rows = const CsvToListConverter().convert(input, eol: '\n');
  final titles = rows.first;
  rows.removeAt(0);
  final dic = Dictionary(data: rows, titles: titles, withNormalize: true);

  // To regenerate prepared datasets from the CSV, uncomment this block.
  // The label index and serialization format match the original experiment.
  // final preparedDataset = prepareElmanDataset(
  //   titles: titles,
  //   data: rows,
  //   dic: dic,
  //   labelIndex: 4,
  // );
  // final trainInputs = preparedDataset['train_ds']!;
  // final trainLabels = preparedDataset['train_labels']!;
  // final testInputs = preparedDataset['test_ds']!;
  // final testLabels = preparedDataset['test_labels']!;
  // saveDataset(
  //   path: elmanTrainDatasetPath,
  //   data: trainInputs,
  //   labels: trainLabels,
  // );
  // saveDataset(
  //   path: elmanTestDatasetPath,
  //   data: testInputs,
  //   labels: testLabels,
  // );

  final trainDataset = loadDataset(path: elmanTrainDatasetPath);
  final testDataset = loadDataset(path: elmanTestDatasetPath);
  final trainInputs = trainDataset['data'] as List<List<double>>;
  final trainLabels = trainDataset['labels'] as List<double>;
  final testInputs = testDataset['data'] as List<List<double>>;
  final testLabels = testDataset['labels'] as List<double>;
  const epoch = 10;
  const step = 5;
  final nn = Elman(
    trainLabels: trainLabels,
    trainInputs: trainInputs,
    testInputs: testInputs,
    testLabels: testLabels,
    layers: [
      Layer(numOfNeurons: 20, activationFunction: ActivationFunction.sigmoid),
      Layer(numOfNeurons: 1, activationFunction: ActivationFunction.sigmoid),
    ],
    lr: 0.1,
    epoch: epoch,
    step: step,
  );
  nn.loadWeights(elmanWeightsPath);
  nn.train(
    callBack: (e) {
      // if (e > 3 && e % (epoch / 3).floor() == 0) {
      //   nn.lr /= 10;
      // }
      // nn.saveWeights('artifacts/weights/elman_10_neuron.w.mnb');
    },
  );

  for (var e = 0; e < 50; e++) {
    final batch = <List>[];
    for (var i = e; i < step; i++) {
      batch.add(testInputs[i]);
    }
    nn.feedInput(batch);
    final output = nn.modelOutput().first;
    final desired = dic.fromToken(
      title: titles[3],
      token: testLabels[e + step - 1],
      decodeFromDictionary: true,
    );
    final actual = dic.fromToken(
      title: titles[3],
      token: output,
      decodeFromDictionary: false,
    );
    print(
      '=====================================================================================',
    );
    print('des= $desired');
    print('act= $actual');
    print('diff ${(desired - actual).abs()}');
  }
}
