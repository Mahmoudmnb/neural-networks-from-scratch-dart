# Refactor Notes

## Summary

This refactor reorganized the project into a clearer Dart package-style layout while preserving the original educational neural-network implementation.

The neural-network math was intentionally kept the same. The changes are limited to structure, naming wrappers, imports, documentation comments, and clearer example entry points.

## Original Structure

- Dart source files were at the repository root:
  - `main.dart`
  - `mlp.dart`
  - `elman.dart`
  - `methods.dart`
  - `dictionary.dart`
- CSV datasets were at the repository root:
  - `Breast_Cancer.csv`
  - `NetFlix.csv`
- Saved weights and prepared datasets were at the repository root:
  - `*.w.mnb`
  - `*.ds.mnb`
- Documentation files were at the repository root:
  - `Backpropagation .docx`
  - `Elman.docx`
  - `NN_Report_template.docx`
- Generated/editor files were tracked:
  - `.dart_tool/`
  - `.vscode/`

## New Structure

- `bin/mlp_example.dart`
- `bin/elman_example.dart`
- `lib/neural_network/activation_functions.dart`
- `lib/neural_network/neuron.dart`
- `lib/neural_network/layer.dart`
- `lib/neural_network/mlp.dart`
- `lib/neural_network/elman.dart`
- `lib/data/dataset_utils.dart`
- `lib/data/dictionary.dart`
- `data/Breast_Cancer.csv`
- `data/NetFlix.csv`
- `artifacts/weights/`
- `artifacts/prepared_datasets/`
- `docs/`
- `README.md`
- `.gitignore`

The root `main.dart` remains as a small compatibility entry point that runs the MLP example.

## Files Renamed

- `methods.dart` -> `lib/data/dataset_utils.dart`

No persisted artifact filenames were renamed. Weight files and prepared dataset files keep their original names inside the new artifact directories.

## Files Moved

- `mlp.dart` -> `lib/neural_network/mlp.dart`
- `elman.dart` -> `lib/neural_network/elman.dart`
- `dictionary.dart` -> `lib/data/dictionary.dart`
- `Breast_Cancer.csv` -> `data/Breast_Cancer.csv`
- `NetFlix.csv` -> `data/NetFlix.csv`
- `*.w.mnb` -> `artifacts/weights/`
- `*.ds.mnb` -> `artifacts/prepared_datasets/`
- `Backpropagation .docx` -> `docs/Backpropagation .docx`
- `Elman.docx` -> `docs/Elman.docx`
- `NN_Report_template.docx` -> `docs/NN_Report_template.docx`

## Naming Improvements

- `AF` remains available as a compatibility class, while new code uses `ActivationFunction`.
- `sigFun` remains available as a compatibility wrapper, while new code uses `sigmoidActivation`.
- `rluFun` remains available as a compatibility wrapper, while new code uses `reluActivation`.
- `saveWights` remains available as a compatibility wrapper, while new code uses `saveWeights`.
- `prepare` remains available as a compatibility wrapper, while new code uses `prepareDataset`.
- `prepareElmanDs` remains available as a compatibility wrapper, while new code uses `prepareElmanDataset`.
- `saveDs` remains available as a compatibility wrapper, while new code uses `saveDataset`.
- `loadDs` remains available as a compatibility wrapper, while new code uses `loadDataset`.
- `decodeFormDic` remains available for compatibility, while `decodeFromDictionary` was added as a clearer optional parameter.

## Readability Improvements

- Split duplicated activation, layer, neuron, and input-node logic into focused files.
- Added class-level documentation for network, layer, neuron, and dictionary components.
- Added method documentation around dataset preparation, forward input feeding, backpropagation, training loops, and weight persistence.
- Added comments that identify saved `.mnb` formats and where to regenerate prepared datasets.
- Separated the MLP and Elman experiments into runnable files under `bin/`.
- Added a minimal README with current runnable commands.
- Added `.gitignore` entries for Dart build/cache folders, editor metadata, logs, and temporary files.

## Behavior Preservation

- Network architecture was not intentionally changed.
- Forward propagation was not intentionally changed.
- Backpropagation was not intentionally changed.
- Weight-update formulas were not intentionally changed.
- Activation behavior was not intentionally changed.
- Dataset contents were not changed.
- Saved weight serialization format was not intentionally changed.
- Prepared dataset serialization format was not intentionally changed.
- Existing `.mnb` filenames were preserved and moved into clearer artifact directories.
- The root `main.dart` still launches the MLP experiment for compatibility.

## Validation Performed

- `dart format .`
  - Result: succeeded.
- `dart pub get`
  - First attempt failed because the sandbox could not write to the Flutter/Dart SDK cache.
  - Retried with approval.
  - Result: succeeded.
  - Output noted `csv 5.1.1 (8.0.0 available)` and one newer incompatible package version. Dependency versions were not upgraded.
- `dart analyze`
  - Result: succeeded with `No issues found!`.
- `dart run bin/elman_example.dart`
  - First attempt failed because the sandbox could not write to the Flutter/Dart SDK cache.
  - Retried with approval.
  - Result: succeeded. The Elman example trained for 10 epochs and printed its evaluation rows.
- `dart run bin/mlp_example.dart`
  - Not run because the current MLP callback saves weights during training, which would mutate a preserved artifact.
- `dart test`
  - Not run because no `test/` directory or `*_test.dart` files were found.
- `git rm --cached -r .dart_tool .vscode`
  - Attempted because those generated/editor files are currently tracked.
  - Result: failed because `.git/index.lock` could not be created on this filesystem.
  - `.gitignore` was still added so future untracked generated/editor files are ignored.

## Potential Issues Not Changed

- `lib/neural_network/mlp.dart` and `lib/neural_network/elman.dart`: hidden-layer derivatives use `output * (1 - output)` even though ReLU is a supported activation option. This may be mathematically inconsistent for ReLU layers, but it matches the original implementation and was not changed.
- `lib/neural_network/elman.dart`: recurrent context is handled by feeding hidden-layer outputs back into input nodes across the provided time window, without backpropagation through time. This may be a simplified Elman training flow, but it was preserved.
- `bin/elman_example.dart`: the final reporting loop preserves the original batch range `for (var i = e; i < step; i++)`, which creates empty batches once `e >= step`. This looks suspicious, but changing it would alter evaluation behavior.
- `lib/neural_network/elman.dart`: Elman train/test loss and accuracy divide by the full dataset length while iterating only to `length - step`. This may understate reported metrics, but it preserves the original behavior.
- `lib/data/dataset_utils.dart`: `prepareDataset` shuffles without a fixed seed. This makes regenerated prepared datasets nondeterministic, but existing saved prepared datasets were preserved.
- `lib/data/dictionary.dart`: normalization is performed before any train/test split in the examples. This may leak test-set scale information into training preprocessing, but it preserves the original dataset interpretation.
- `lib/data/dictionary.dart`: normalization divides by `maxValue - minValue`; a constant column could produce invalid values. Existing datasets were not changed.

## Remaining Technical Debt

- Remove `.dart_tool/` and `.vscode/` from Git tracking when the repository index is writable.
- Add focused tests for dataset serialization, weight load/save compatibility, and small deterministic forward-pass cases.
- Consider adding command-line flags for choosing whether to train, evaluate, or regenerate prepared datasets.
- Consider documenting expected dataset columns and artifact meanings in the future portfolio README.
