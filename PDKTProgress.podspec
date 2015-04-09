Pod::Spec.new do |s|
  s.name             = "PDKTProgress"
  s.version          = "0.1.0"
  s.summary          = "Handle progress and subprogress"
  s.description      = <<-DESC
                       This small class handles progress and uses the Decorator Pattern to handle
                        subprogresses so you could decouple your progress operations.
                        It also can create fake progresses for unpredictable time length operations
                       DESC
  s.homepage         = "https://github.com/Produkt/PDKTProgress"
  s.license          = 'MIT'
  s.author           = { "Daniel García" => "fillito@gmail.com" }
  s.source           = { :git => "https://github.com/Produkt/PDKTProgress.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/fillito'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'PDKTProgress.*'
  s.resource_bundles = {

  }
end
