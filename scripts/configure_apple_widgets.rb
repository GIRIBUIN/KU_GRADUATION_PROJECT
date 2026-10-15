# Run before pod install / flutter build on a Mac. Also runs on Linux for project-structure validation.
require 'xcodeproj'
require 'pathname'

root = File.expand_path('..', __dir__)
platforms = ARGV.empty? ? %w[ios macos] : ARGV
raise 'Expected ios or macos' unless (platforms - %w[ios macos]).empty?
bundle = ENV.fetch('KU_BUNDLE_ID', 'com.example.kuTaskManagement')
group = ENV.fetch('KU_APP_GROUP', "group.#{bundle}")
team = ENV['APPLE_DEVELOPMENT_TEAM']

platforms.each do |platform|
  directory = File.join(root, platform)
  project = Xcodeproj::Project.open(File.join(directory, 'Runner.xcodeproj'))
  runner = project.targets.find { |target| target.name == 'Runner' }
  raise 'Runner target missing' unless runner
  widget = project.targets.find { |target| target.name == 'KuTodoWidgets' } ||
    project.new_target(:app_extension, 'KuTodoWidgets', platform == 'ios' ? :ios : :osx, platform == 'ios' ? '17.0' : '14.0')
  desktop_only = platform == 'macos' && ENV['KU_MACOS_DESKTOP_ONLY'] == '1'
  source_group = project.main_group.groups.find { |item| item.display_name == 'KU Widgets' } || project.main_group.new_group('KU Widgets')
  add_source = lambda do |target, path|
    reference = source_group.files.find { |file| file.path == path } || source_group.new_file(path)
    target.source_build_phase.add_file_reference(reference) unless target.source_build_phase.files_references.include?(reference)
  end
  add_source.call(runner, '../apple/Runner/AppleWidgetBridge.swift')
  add_source.call(runner, '../apple/Shared/WidgetStore.swift')
  add_source.call(runner, '../apple/Shared/WidgetIntents.swift')
  add_source.call(widget, '../apple/Shared/WidgetStore.swift')
  add_source.call(widget, '../apple/Shared/WidgetIntents.swift')
  add_source.call(widget, '../apple/Widgets/KuTodoWidgets.swift')

  [runner, widget].each do |target|
    ['WidgetKit.framework', 'SwiftUI.framework', 'AppIntents.framework', 'libsqlite3.tbd', 'UserNotifications.framework'].each do |name|
      path = name.end_with?('.tbd') ? "usr/lib/#{name}" : "System/Library/Frameworks/#{name}"
      reference = project.frameworks_group.files.find { |file| file.path == path }
      unless reference
        reference = project.new(Xcodeproj::Project::Object::PBXFileReference)
        reference.path = path
        reference.source_tree = 'SDKROOT'
        reference.last_known_file_type = name.end_with?('.tbd') ? 'sourcecode.text-based-dylib-definition' : 'wrapper.framework'
        project.frameworks_group.children << reference
      end
      target.frameworks_build_phase.add_file_reference(reference) unless target.frameworks_build_phase.files_references.include?(reference)
    end
    target.build_configurations.each do |configuration|
      settings = configuration.build_settings
      settings['KU_WIDGET_APP_GROUP'] = group
      settings[platform == 'ios' ? 'IPHONEOS_DEPLOYMENT_TARGET' : 'MACOSX_DEPLOYMENT_TARGET'] = platform == 'ios' ? '17.0' : '14.0'
      settings['DEVELOPMENT_TEAM'] = team if team && !team.empty?
      settings['CODE_SIGN_STYLE'] = 'Automatic'
      settings['SWIFT_VERSION'] = '5.0'
      if ENV['KU_APPLE_UNSIGNED'] == '1'
        settings['CODE_SIGNING_ALLOWED'] = 'NO'
        settings['CODE_SIGNING_REQUIRED'] = 'NO'
      else
        settings.delete('CODE_SIGNING_ALLOWED')
        settings.delete('CODE_SIGNING_REQUIRED')
      end
      if platform == 'ios'
        profile = ENV[target == widget ? 'IOS_WIDGET_PROFILE_UUID' : 'IOS_APP_PROFILE_UUID']
        if profile && !profile.empty?
          settings['CODE_SIGN_STYLE'] = 'Manual'
          settings['PROVISIONING_PROFILE_SPECIFIER'] = profile
          settings['CODE_SIGN_IDENTITY'] = 'Apple Distribution'
        end
      end
      if target == widget
        settings['PRODUCT_BUNDLE_IDENTIFIER'] = "#{bundle}.widgets"
        settings['PRODUCT_NAME'] = 'KuTodoWidgets'
        settings['INFOPLIST_FILE'] = '../apple/Widgets/Info.plist'
        settings['CODE_SIGN_ENTITLEMENTS'] = platform == 'ios' ? '../apple/Widgets/Widget.entitlements' : '../apple/Widgets/WidgetMac.entitlements'
        settings['SKIP_INSTALL'] = 'YES'
        settings['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
        settings['MARKETING_VERSION'] = ENV.fetch('KU_VERSION', '0.2.0')
        settings['CURRENT_PROJECT_VERSION'] = ENV.fetch('KU_BUILD_NUMBER', '6')
        settings['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
        settings['GENERATE_INFOPLIST_FILE'] = 'NO'
        settings['TARGETED_DEVICE_FAMILY'] = '1,2' if platform == 'ios'
      else
        settings['PRODUCT_BUNDLE_IDENTIFIER'] = bundle
        original = settings['CODE_SIGN_ENTITLEMENTS']
        original_path = original && File.join(directory, original)
        entitlements = original_path && File.file?(original_path) ? Xcodeproj::Plist.read_from_path(original_path) : {}
        entitlements['com.apple.security.application-groups'] = ['$(KU_WIDGET_APP_GROUP)']
        entitlements.delete('com.apple.security.application-groups') if desktop_only
        entitlements['com.apple.security.network.client'] = true if platform == 'macos'
        path = "Runner/KuWidgets#{configuration.name}.entitlements"
        Xcodeproj::Plist.write_to_path(entitlements, File.join(directory, path))
        settings['CODE_SIGN_ENTITLEMENTS'] = path
      end
    end
  end
  runner.add_dependency(widget) unless runner.dependencies.any? { |dependency| dependency.target == widget }
  embed = runner.copy_files_build_phases.find { |phase| phase.name == 'Embed App Extensions' } || runner.new_copy_files_build_phase('Embed App Extensions')
  embed.dst_subfolder_spec = '13'
  unless embed.files_references.include?(widget.product_reference)
    embed.add_file_reference(widget.product_reference).settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
  end
  if desktop_only
    runner.dependencies.select { |dependency| dependency.target == widget }.each(&:remove_from_project)
    embed.files.each(&:remove_from_project)
    widget.remove_from_project
  end
  info_path = File.join(directory, 'Runner', 'Info.plist')
  info = Xcodeproj::Plist.read_from_path(info_path)
  info['KuWidgetAppGroup'] = '$(KU_WIDGET_APP_GROUP)'
  info['FlutterDeepLinkingEnabled'] = false
  types = info.fetch('CFBundleURLTypes', []).reject { |entry| entry.fetch('CFBundleURLSchemes', []).include?('kutodo') }
  info['CFBundleURLTypes'] = types + [{ 'CFBundleURLName' => bundle, 'CFBundleURLSchemes' => ['kutodo'] }]
  Xcodeproj::Plist.write_to_path(info, info_path)
  project.save
  puts "Configured #{platform}: #{desktop_only ? 'desktop window widgets' : 'Runner + KuTodoWidgets'}, App Group #{group}"
end
