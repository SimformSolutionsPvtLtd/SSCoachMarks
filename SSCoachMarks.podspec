
Pod::Spec.new do |s|
  s.name 		= 'SSCoachMarks'
  s.version 		= '1.0.0'
  s.summary		= 'SSCoachMarks SDK for SwiftUI enables customizable view highlighting with guided navigation, button styling, background customization, and timed transitions—perfect for onboarding and tutorials.'
  s.platform 		= :ios
  s.swift_versions 	= '5.9'
  s.description = <<-DESC
The SSCoachMarks SDK in SwiftUI is designed to showcase or highlight specific views with titles, descriptions, and customizable content. It provides seamless navigation features, including Next, Back, and Done buttons for a guided experience. The SDK allows complete customization of these buttons to align with your design preferences. Additionally, it supports adding custom views for enhanced flexibility, making it an ideal tool for creating intuitive onboarding or tutorial flows.
DESC
    
  s.homepage 		= 'https://github.com/SimformSolutionsPvtLtd/SSCoachMarks'
  s.license 		= { :type => 'MIT', :file => 'LICENSE' }
  s.author 		= { 'Yagnik Bavishi' => 'yagnik.b@simformsolutions.com' }
  s.source 		= { :git => 'https://github.com/SimformSolutionsPvtLtd/SSCoachMarks.git', :tag => s.version.to_s }
  s.social_media_url 	= 'https://www.simform.com' 
  s.ios.deployment_target = '17.0'
    
  s.source_files      	= 'Sources/**/*.{swift}'
  s.frameworks 		= ['SwiftUI']
    
end
