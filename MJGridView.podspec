#
# Be sure to run `pod lib lint MJGridView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MJGridView'
  s.version          = '0.6.5'
  s.summary          = 'A view for displaying a zoomable coordinate grid.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
A view for displaying a zoomable coordinate grid. Grid is rendered with more details as it's zoomed in, or rendered with less details as it's zoomed out.
Made using `CATiledLayer`. Rendered in a grid of tiles, each tile asynchronously on a separate thread.
                       DESC

  s.homepage         = 'https://github.com/milosjagetic/MJZoomableGridView'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Miloš Jagetić' => 'milos.jagetic@gmail.com' }
  s.source           = { :git => 'https://github.com/Miloš Jagetić/MJGridView.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'MJGridView/Classes/**/*'

end
