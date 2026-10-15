require 'xcodeproj'
require 'yaml'
root = File.expand_path('..', __dir__)
%w[ios macos].each do |platform|
  directory = File.join(root, platform)
  project = Xcodeproj::Project.open(File.join(directory, 'Runner.xcodeproj'))
  runner = project.targets.find { |target| target.name == 'Runner' }
  widget = project.targets.find { |target| target.name == 'KuTodoWidgets' }
  raise "Missing #{platform} targets" unless runner && widget
  raise 'Missing app-extension product type' unless widget.product_type == 'com.apple.product-type.app-extension'
  raise 'Missing dependency' unless runner.dependencies.any? { |dependency| dependency.target == widget }
  raise 'Missing embedded widget' unless runner.copy_files_build_phases.any? { |phase| phase.dst_subfolder_spec == '13' && phase.files_references.include?(widget.product_reference) }
  [runner, widget].each do |target|
    sources = target.source_build_phase.files_references.map(&:path)
    %w[WidgetStore.swift WidgetIntents.swift].each do |source|
      raise "Missing shared source #{source}" unless sources.any? { |path| path.end_with?(source) }
    end
    target.build_configurations.each do |configuration|
      settings = configuration.build_settings
      entitlements = Xcodeproj::Plist.read_from_path(File.expand_path(settings['CODE_SIGN_ENTITLEMENTS'], directory))
      raise 'Wrong shared container entitlement' unless entitlements['com.apple.security.application-groups'] == ['$(KU_WIDGET_APP_GROUP)']
      raise 'Missing group setting' unless settings['KU_WIDGET_APP_GROUP'] && !settings['KU_WIDGET_APP_GROUP'].empty?
      raise 'Widget/App group mismatch' unless settings['KU_WIDGET_APP_GROUP'] == runner.build_configurations.first.build_settings['KU_WIDGET_APP_GROUP']
    end
  end
  info = Xcodeproj::Plist.read_from_path(File.join(directory, 'Runner/Info.plist'))
  raise 'Missing edit URL scheme' unless info['CFBundleURLTypes'].any? { |entry| entry.fetch('CFBundleURLSchemes', []).include?('kutodo') }
  raise 'Flutter must let the native bridge route widget links' unless info['FlutterDeepLinkingEnabled'] == false
  puts "#{platform}: targets, shared database/intents, embedding, entitlements and edit links OK"
end
Dir[File.join(root, '.github/workflows/*.yml')].each do |path|
  YAML.load_file(path)
  puts "YAML OK: #{File.basename(path)}"
end
