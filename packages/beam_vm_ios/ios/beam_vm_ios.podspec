#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
#
Pod::Spec.new do |s|
  s.name             = 'beam_vm_ios'
  s.version          = '1.0.0'
  s.summary          = 'iOS implementation of beam_vm plugin with bundled BEAM runtime'
  s.description      = <<-DESC
iOS implementation of the beam_vm Flutter plugin for embedding and running
the Erlang/Elixir BEAM virtual machine on iOS devices.
Bundles liberlang.xcframework for arm64 devices and simulators.
                       DESC
  s.homepage         = 'https://github.com/gsmlg-app/beam_vm'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'gsmlg-app' => 'noreply@gsmlg.org' }
  s.source           = { :path => '.' }

  # Source files
  s.source_files = 'Classes/**/*'

  # Bundled xcframework
  s.vendored_frameworks = 'Assets/liberlang.xcframework'

  # Dependencies
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Build settings
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    # Link system libraries required by liberlang
    'OTHER_LDFLAGS' => '-lz -lm -ldl'
  }

  s.swift_version = '5.0'
end
