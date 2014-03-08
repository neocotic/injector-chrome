# [Injector](http://neocotic.com/injector)
#
# (c) 2014 Alasdair Mercer
#
# Freely distributable under the MIT license

# Inline installation
# -------------------

# Injector's extension ID is currently using.
id         = chrome.i18n.getMessage('@@extension_id')
# Names of the classes to be added to the targeted elements.
newClasses = [ 'disabled' ]
# Names of the classes to be removed from the targeted elements.
oldClasses = [ 'chrome_install_button' ]

# Disable all "Install" links on the homepage for Template.
links = document.querySelectorAll("a.#{oldClasses[0]}[href$=#{id}]")
for link in links
  link.innerHTML = link.innerHTML.replace('Install', 'Installed')

  link.classList.add(cls)    for cls in newClasses
  link.classList.remove(cls) for cls in oldClasses
