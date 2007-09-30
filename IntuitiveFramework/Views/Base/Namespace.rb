

# get the path of this file
path = File.dirname(File.expand_path(__FILE__))


# Load all the Classes and modules in this Namespace
['MixinBindsToModel',
'MixinContainerChild',
'MixinContainerParent',
'MixinEvents',
'MixinFocus',
'MixinImage',
'MixinKeyboard',
'MixinMouse',
'MixinMouseDrag',
'MixinText',
'MixinRefresh',
'ContainerChild',
'ContainerParentAndChild',
'ContainerParent',
].each { |file_name| require "#{path}/#{file_name}" }
