import 'package:custom_lint_builder/custom_lint_builder.dart';

import 'src/rx_disposal_rule.dart';

PluginBase createPlugin() => _OccamLinterPlugin();

class _OccamLinterPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        RxDisposalRule(),
      ];
}
