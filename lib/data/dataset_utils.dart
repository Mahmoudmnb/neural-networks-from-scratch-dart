import 'dart:io';
import 'dart:math';

import 'dictionary.dart';

/// Prepares the MLP classification dataset with the original 80/20 split.
Map<String, List> prepareDataset({
  required List titles,
  required List data,
  required Dictionary dic,
}) {
  data.shuffle(Random());
  final trainDataset = <List<double>>[];
  final testDataset = <List<double>>[];
  final trainLabels = <double>[];
  final testLabels = <double>[];
  for (var i = 0; i < (data.length * 0.8).floor(); i++) {
    final rowInputs = <double>[];
    for (var j = 0; j < data[i].length; j++) {
      if (j == data[i].length - 1) {
        trainLabels.add(dic.toToken(title: titles[j], element: data[i][j]));
      } else {
        rowInputs.add(dic.toToken(title: titles[j], element: data[i][j]));
      }
    }
    trainDataset.add(rowInputs);
  }
  for (var i = (data.length * 0.8).floor(); i < data.length; i++) {
    final rowInputs = <double>[];
    for (var j = 0; j < data[i].length; j++) {
      if (j == data[i].length - 1) {
        testLabels.add(dic.toToken(title: titles[j], element: data[i][j]));
      } else {
        rowInputs.add(dic.toToken(title: titles[j], element: data[i][j]));
      }
    }
    testDataset.add(rowInputs);
  }
  return {
    'train_ds': trainDataset,
    'test_ds': testDataset,
    'train_labels': trainLabels,
    'test_labels': testLabels,
  };
}

/// Backward-compatible wrapper for the original helper name.
Map<String, List> prepare({
  required List titles,
  required List data,
  required Dictionary dic,
}) {
  return prepareDataset(titles: titles, data: data, dic: dic);
}

/// Prepares the sequence-style dataset used by the Elman example.
Map<String, List> prepareElmanDataset({
  required List titles,
  required List data,
  required Dictionary dic,
  required int labelIndex,
}) {
  final trainDataset = <List<double>>[];
  final testDataset = <List<double>>[];
  final trainLabels = <double>[];
  final testLabels = <double>[];
  for (var i = 0; i < (data.length * 0.8).floor(); i++) {
    final rowInputs = <double>[];
    for (var j = 0; j < data[i].length; j++) {
      if (j == labelIndex) {
        trainLabels.add(dic.toToken(title: titles[j], element: data[i][j]));
      }
      rowInputs.add(dic.toToken(title: titles[j], element: data[i][j]));
    }
    trainDataset.add(rowInputs);
  }
  for (var i = (data.length * 0.8).floor(); i < data.length; i++) {
    final rowInputs = <double>[];
    for (var j = 0; j < data[i].length; j++) {
      if (j == labelIndex) {
        testLabels.add(dic.toToken(title: titles[j], element: data[i][j]));
      }
      rowInputs.add(dic.toToken(title: titles[j], element: data[i][j]));
    }
    testDataset.add(rowInputs);
  }
  trainLabels.removeAt(0);
  trainDataset.removeLast();
  testLabels.removeAt(0);
  testDataset.removeLast();
  return {
    'train_ds': trainDataset,
    'test_ds': testDataset,
    'train_labels': trainLabels,
    'test_labels': testLabels,
  };
}

/// Backward-compatible wrapper for the original Elman dataset helper name.
Map<String, List> prepareElmanDs({
  required List titles,
  required List data,
  required Dictionary dic,
  required int labelIndex,
}) {
  return prepareElmanDataset(
    titles: titles,
    data: data,
    dic: dic,
    labelIndex: labelIndex,
  );
}

/// Saves prepared dataset rows in the original text `.mnb` format.
void saveDataset({
  required String path,
  required List<List> data,
  required List labels,
}) {
  print('start saving ........');
  var text = '';
  for (var i = 0; i < data.length; i++) {
    for (var j = 0; j < data[i].length; j++) {
      text += data[i][j].toString();
      if (j < data[i].length - 1) {
        text += ' ';
      }
    }
    text += '\t';
    text += labels[i].toString();
    if (i < data.length - 1) {
      text += '\n';
    }
  }
  File(path).writeAsStringSync(text);
  print('saving finished ...........................');
}

/// Backward-compatible wrapper for the original helper name.
void saveDs({
  required String path,
  required List<List> data,
  required List labels,
}) {
  saveDataset(path: path, data: data, labels: labels);
}

/// Loads prepared dataset rows from the original text `.mnb` format.
Map<String, dynamic> loadDataset({required String path}) {
  final text = File(path).readAsStringSync();
  final data = <List<double>>[];
  final labels = <double>[];
  final lines = text.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final parts = lines[i].split('\t');
    final inputs = parts.first;
    labels.add(double.parse(parts[1].toString()));
    final rowData = inputs.split(' ');
    final rowInputs = <double>[];
    for (var j = 0; j < rowData.length; j++) {
      rowInputs.add(double.parse(rowData[j].toString()));
    }
    data.add(rowInputs);
  }
  return {'data': data, 'labels': labels};
}

/// Backward-compatible wrapper for the original helper name.
Map<String, dynamic> loadDs({required String path}) => loadDataset(path: path);
