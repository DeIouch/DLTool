Pod::Spec.new do |spec|

  spec.name         = "DLTool"
  spec.version      = "0.0.3"
  spec.summary      = "DLTool."

  spec.description  = <<-DESC
		      DLTool of Delouch
                      DESC

  spec.homepage     = "https://github.com/DeIouch"
  spec.license      = "MIT"
  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author       = "Delouch"

  spec.platform     = :ios, "9.0"

  spec.source       = { :git => "https://github.com/DeIouch/DLTool.git", :tag => "#{spec.version}" }

  spec.source_files  = "DLTool", "DLToolDemo/DLToolDemo/DLTool/Classes/**/*"

  # spec.resources = "Resources/*.png"

  spec.framework  = "UIKit"
  # spec.frameworks = "SomeFramework", "AnotherFramework"

  # spec.dependency "JSONKit", "~> 1.4"

end
