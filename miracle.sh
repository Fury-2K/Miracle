#!/bin/bash

# Default variable values
verbose_mode=false

# --- ---  --- ---  --- ---  BASH SETUP --- ---  --- ---  --- ---  --- ---

# we need to check and update bash profile too
function bash_shell_env_setup {    
	export LANG="en_US.UTF-8"
	export LC_ALL="en_US.UTF-8"
	export PATH="$HOME/.rbenv/bin:$PATH"
	export PATH="/opt/homebrew/bin:$PATH"
	## Remove rbenv-shim if it already exists, to prevent silent failure of 'eval "$(rbenv init -)"'
	rbenv_shim_path="$HOME/.rbenv/shims/.rbenv-shim"
	if test -f $rbenv_shim_path; then
		rm $rbenv_shim_path
	fi
	if [[ $SHELL == *"zsh"* ]]; then
		eval "$(rbenv init - zsh)"
	else 
		eval "$(rbenv init -)"
	fi 
}

# --- ---  --- ---  --- ---  BREW INSTALL --- ---  --- ---  --- ---  --- ---

function cleanup_brew_install {
	echo "*** Failed to install brew ***"
	echo "Please re-run the script once brew installation is done"
	exit -1
}

function install_brew {
	trap cleanup_brew_install EXIT

	echo "fixing brew..."
	echo "    install brew"
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	brew doctor
	if [ $? -ne 0 ]; then
		exit -1
	fi
	echo "    ready to Brew"
}

# --- ---  --- ---  --- ---  RBENV INSTALL --- ---  --- ---  --- ---  --- ---

function cleanup_rbenv_install {
	echo "*** Failed to install rbenv ***"
	echo "Please re-run the script once ruby installation is done"
	exit -1
}

function install_rbenv {
	trap cleanup_rbenv_install EXIT

	echo "fixing rbenv..."
	echo "    install rbenv"
	brew install rbenv
	if [ $? -ne 0 ]; then
		exit -1
	fi

	echo "    ready to use rbenv"
}

# --- ---  --- ---  --- ---  RUBY SETUP --- ---  --- ---  --- ---  --- ---

function install_ruby_using_rbenv {
	rbenv install 2.7.6    
}

function install_ruby {
	echo "fixing ruby..."
	echo "    installing ruby version using rbenv"
	install_ruby_using_rbenv

	if [ $? -ne 0 ]; then
		echo "Looks like ruby version 2.7.6 is not available in current rbenv, Upgrading ruby-build to latest version..."
		brew upgrade rbenv ruby-build
		echo "    Attempting install ruby 2.7.6 using updated ruby-build"
	install_ruby_using_rbenv        
	if [ $? -ne 0 ]; then
			exit -1
		fi
	fi
    
    echo 'eval "$(rbenv init -)"' >> ~/.zshrc
	echo "    rbenv successfully updated ruby to latest ruby required version"
}

# --- ---  --- ---  --- ---  VALIDATE BREW --- ---  --- ---  --- ---  --- ---

function validate_brew {
	#fix brew if required
	echo "* checking brew..."
	brew --version >> /dev/null 2>&1
	if [ $? -ne 0 ]; then
		install_brew
	else
   	echo "    Brew already installed"
	fi

	echo "* [failable] Brewing formuleas ..."
	brew tap --repair
	brew tap Homebrew/bundle

	# Updated Homebrew to check for updates
	brew update
}

# --- ---  --- ---  --- ---  VALIDATE RBENV --- ---  --- ---  --- ---  --- ---

function exec_rbenv_script {
	#fix rbenv if required
	echo "* checking rbenv..."  
	rbenv -v >> /dev/null 2>&1
	if [ $? -ne 0 ]; then
		install_rbenv
	else
		echo "    rbenv already installed"
	fi
}

# --- ---  --- ---  --- ---  VALIDATE RUBY (using rbenv) --- ---  --- ---  --- ---  --- ---

function exec_ruby_scripts {
	#fix ruby if required
	rm  ~/.rbenv/shims/.rbenv-shim || true
	echo "* checking ruby version..."
	expected_ruby_major_version=276

	# we iterate over all available ruby versions with rbenv, if an equal or higher version found we use it
	for ruby_major_version in $(ls ~/.rbenv/versions | sort -nr)
	do
		echo "    * comparing ruby version ${ruby_major_version}"
		ruby_major_version_without_dots=`echo $ruby_major_version | tr -d '.'`
		if [[ $ruby_major_version == *p* ]]; then
			echo "   * you have installed a BETA version, that would be ignored during lookup ..."
		else
		if [ "$ruby_major_version_without_dots" -ge "$expected_ruby_major_version" ]; then
			# set this ruby_major_version as shell rbenv
			echo "rbenv shell $ruby_major_version"
			rbenv shell $ruby_major_version
			if [ -z "$SKIP_RBENV_GLOBAL_CONFIG_CHANGE" ]; then
				echo "Setting rbenv global version to $ruby_major_version"
				rbenv global $ruby_major_version
			fi
			break
		fi
	fi    
	done

	#verify if the above exercize has set `shell ruby` or we should do it explicitly
	current_shell_ruby_version=$(( `rbenv shell | awk -F'.' '{print $1$2$3}'` ))
	if [ "$current_shell_ruby_version" -lt "$expected_ruby_major_version" ]; then
		install_ruby
		rbenv shell 2.7.6
		if [ -z "$SKIP_RBENV_GLOBAL_CONFIG_CHANGE" ]; then
			echo "Setting rbenv global version to 2.7.6"
			rbenv global 2.7.6
		fi
	fi

	# check ruby paths, we expect to use rbenv ruby
	actual_ruby_path=`which ruby`
	expected_ruby_path=""`stat -f "%N" ~`"/.rbenv/shims/ruby"
	if [ "$actual_ruby_path" = "$expected_ruby_path" ]; then
		echo "    ruby env is set correctly..."
	else
		echo "    ruby env is not set correctly !!!"
		echo "*** which ruby should produce $expected_ruby_path ***"

		exit -1
	fi
}

# --- ---  --- ---  --- ---  NEW SYSTEM INSTALLATION --- ---  --- ---  --- ---  --- ---

# function cleanup_aria2_install {
#     echo "*** Failed to install aria2 ***"
#     echo "Continuing with URLSession."
# }


# function install_aria2 {
#     trap cleanup_aria2_install EXIT
	
#     brew install aria2
#     if [ $? -ne 0 ]; then
#         exit -1
#     fi
#     xcodes install --latest --experimental-unxip
# }

function cleanup_xcodes_install {
	echo "*** Failed to install xcodes ***"
	echo "Please re-run the script once ruby installation is done"
	exit -1
}

function install_latest_xcode {
	trap cleanup_xcodes_install EXIT

	brew install aria2
	brew install xcodesorg/made/xcodes
	if [ $? -ne 0 ]; then
		exit -1
	fi
	xcodes install --latest --experimental-unxip
}

function new_system_install_software {
	# Apps
	apps=(
		discord
		slack
		firefox
		spotify
		iterm2
		sublime-text
		visual-studio-code
		vlc
		obsidian
		android-studio
		raycast
	)
	
	# OhMyZsh
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	
	echo "installing apps with Cask..."
	brew install --cask ${apps[@]}
	brew cleanup
	# Xcode
	install_latest_xcode

	echo """
	Setup the following before restarting - 
	iterm2
	obsidian
	raycast
	"""
}

# --- ---  --- ---  --- ---  OH MY ZSH SETUP --- ---  --- ---  --- ---  --- ---

function setup_oh_my_zsh() {
	#Install Zsh & Oh My Zsh
	echo "Installing Oh My ZSH..."
	curl -L http://install.ohmyz.sh | sh

	echo "Setting up Oh My Zsh theme..."
	cd  /Users/bradparbs/.oh-my-zsh/themes
	curl https://gist.githubusercontent.com/bradp/a52fffd9cad1cd51edb7/raw/cb46de8e4c77beb7fad38c81dbddf531d9875c78/brad-muse.zsh-theme > brad-muse.zsh-theme

	echo "Setting up Zsh plugins..."
	cd ~/.oh-my-zsh/custom/plugins
	git clone git://github.com/zsh-users/zsh-syntax-highlighting.git

	echo "Setting ZSH as shell..."
	chsh -s /bin/zsh
}

# --- ---  --- ---  --- ---  GIT SETUP --- ---  --- ---  --- ---  --- ---

function setup_git() {
	echo "Installing Git..."
	brew install git

	echo "Git config"

	git config --global user.name "Manas Aggarwal"
	git config --global user.email devfury.manas@gmail.com
}

# --- ---  --- ---  --- ---  BASIC MAC SETUP --- ---  --- ---  --- ---  --- ---

function mac_basic_setup() {
	echo "Disabling OS X Gate Keeper"
	echo "(You'll be able to install any app you want from here on, not just Mac App Store apps)"
	sudo spctl --master-disable
	sudo defaults write /var/db/SystemPolicy-prefs.plist enabled -string no
	defaults write com.apple.LaunchServices LSQuarantine -bool false

	echo "Enabling - Saving to disk (not to iCloud) by default"
	defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

	echo "Enabling full keyboard access for all controls (e.g. enable Tab in modal dialogs)"
	defaults write NSGlobalDomain AppleKeyboardUIMode -int 3


	echo "Enabling subpixel font rendering on non-Apple LCDs"
	defaults write NSGlobalDomain AppleFontSmoothing -int 2

	echo "Showing icons for hard drives, servers, and removable media on the desktop"
	defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true

	echo "Showing all filename extensions in Finder by default"
	defaults write NSGlobalDomain AppleShowAllExtensions -bool true

	echo "Use column view in all Finder windows by default"
	defaults write com.apple.finder FXPreferredViewStyle Clmv

	echo "Setting the icon size of Dock items to 36 pixels for optimal size/screen-realestate"
	defaults write com.apple.dock tilesize -int 36

	# #"Speeding up Mission Control animations and grouping windows by application"
	# defaults write com.apple.dock expose-animation-duration -float 0.1
	# defaults write com.apple.dock "expose-group-by-app" -bool true

	# #"Setting Dock to auto-hide and removing the auto-hiding delay"
	# defaults write com.apple.dock autohide -bool true
	# defaults write com.apple.dock autohide-delay -float 0
	# defaults write com.apple.dock autohide-time-modifier -float 0

	echo "Setting email addresses to copy as 'foo@example.com' instead of 'Foo Bar <foo@example.com>' in Mail.app"
	defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

	echo "Enabling UTF-8 ONLY in Terminal.app and setting the Pro theme by default"
	defaults write com.apple.terminal StringEncodings -array 4
	defaults write com.apple.Terminal "Default Window Settings" -string "Pro"
	defaults write com.apple.Terminal "Startup Window Settings" -string "Pro"

	# #"Preventing Time Machine from prompting to use new hard drives as backup volume"
	# defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

	# #"Disable the sudden motion sensor as its not useful for SSDs"
	# sudo pmset -a sms 0

	#"Speeding up wake from sleep to 24 hours from an hour"
	# http://www.cultofmac.com/221392/quick-hack-speeds-up-retina-macbooks-wake-from-sleep-os-x-tips/
	# sudo pmset -a standbydelay 86400

	echo "Disable annoying backswipe in Chrome"
	defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false

	echo "Setting screenshots location to ~/Desktop"
	defaults write com.apple.screencapture location -string "$HOME/Desktop"

	echo "Setting screenshot format to PNG"
	defaults write com.apple.screencapture type -string "png"

	#"Hiding Safari's bookmarks bar by default"
	# defaults write com.apple.Safari ShowFavoritesBar -bool false

	#"Hiding Safari's sidebar in Top Sites"
	# defaults write com.apple.Safari ShowSidebarInTopSites -bool false

	#"Disabling Safari's thumbnail cache for History and Top Sites"
	# defaults write com.apple.Safari DebugSnapshotsUpdatePolicy -int 2

	echo "Enabling Safari's debug menu"
	defaults write com.apple.Safari IncludeInternalDebugMenu -bool true

	# #"Making Safari's search banners default to Contains instead of Starts With"
	# defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false

	# #"Removing useless icons from Safari's bookmarks bar"
	# defaults write com.apple.Safari ProxiesInBookmarksBar "()"

	# #"Allow hitting the Backspace key to go to the previous page in history"
	# defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled -bool true

	echo "Enabling the Develop menu and the Web Inspector in Safari"
	defaults write com.apple.Safari IncludeDevelopMenu -bool true
	defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
	defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true

	# #"Adding a context menu item for showing the Web Inspector in web views"
	# defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

	echo "Use `~/Downloads/Incomplete` to store incomplete downloads"
	defaults write org.m0k.transmission UseIncompleteDownloadFolder -bool true
	defaults write org.m0k.transmission IncompleteDownloadFolder -string "${HOME}/Downloads/Incomplete"

	#"Don't prompt for confirmation before downloading"
	# defaults write org.m0k.transmission DownloadAsk -bool false

	echo "Trash original torrent files"
	defaults write org.m0k.transmission DeleteOriginalTorrent -bool true

	# #"Hide the donate message"
	# defaults write org.m0k.transmission WarningDonate -bool false

	# #"Hide the legal disclaimer"
	# defaults write org.m0k.transmission WarningLegal -bool false

	echo "Disable 'natural' (Lion-style) scrolling"
	defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

	# Don’t automatically rearrange Spaces based on most recent use
	# defaults write com.apple.dock mru-spaces -bool false
}

# --- ---  --- ---  --- ---  ENV SETUP --- ---  --- ---  --- ---  --- ---

function setup_themes() {
    echo "Creating a developer directory...."
    cd && mkdir Developer
    cd Developer
    # mkdir theming
    # cd theming
    
    # Xcode theme setup
    echo "Cloning SundellColors Xcode theme"
    git clone https://github.com/JohnSundell/XcodeTheme.git
    echo "Installing Adobe's Source Code Pro font and this Xcode theme"
    cd XcodeTheme
    swift run
    
    echo "Running Cleanup utility"
    cd ..
    rm -rf XcodeTheme
}

# --- ---  --- ---  --- ---  MAIN EXEC --- ---  --- ---  --- ---  --- ---

# Function to display script usage
usage() {
	echo "Usage: $0 [OPTIONS]"
	echo "Options:"
	echo " -h, --help      Display this help message"
	echo " -v, --verbose   Enable verbose mode"
	echo " -n, --new       Install all the latest and important softwares."
#  echo " -f, --file      FILE Specify an output file"
}

has_argument() {
	[[ ("$1" == *=* && -n ${1#*=}) || ( ! -z "$2" && "$2" != -*)  ]];
}

extract_argument() {
  echo "${2:-${1#*=}}"
}

# Function to handle options and arguments
handle_options() {
	# Setup shell environment if bashrc or zrc is not configured properly
	bash_shell_env_setup
	validate_brew
	exec_rbenv_script
	exec_ruby_scripts

	while [ $# -gt 0 ]; do
		case $1 in
		-h | --help)
			usage
			exit 0
		;;
		-v | --verbose)
			verbose_mode=true
		;;
		-n | --new) 
			setup_git
			setup_oh_my_zsh
			mac_basic_setup
			new_system_install_software
            setup_themes
		;;
	#   -f | --file*)
	#     if ! has_argument $@; then
	#       echo "File not specified." >&2
	#       usage
	#       exit 1
	#     fi

	#     output_file=$(extract_argument $@)

	#     shift
	#     ;;
	  *)
		echo "Invalid option: $1" >&2
		usage
		exit 1
		;;
	esac
	shift
  done
}

# Main script execution
handle_options "$@"

echo "Done! Get....Set....Code!"
