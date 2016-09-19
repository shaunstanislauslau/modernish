#! /module/for/moderni/sh

# modernish sys/dir/traverse
#
# traverse: Recursively walk through a directory, executing a command for
# each file found. Cross-platform, robust replacement for 'find'. Since the
# command name can be a shell function, any functionality of 'find' and
# anything else can be programmed in the shell language.
#
# Usage: traverse [ -d ] <dirname> <commandname>
#
# traverse calls <commandname>, once for each file found within the
# directory <dirname>, with one parameter containing the full pathname
# relative to <dirname>. Any directories found within are automatically
# entered and traversed recursively unless <commandname> exits with status
# 1. Symlinks to directories are not followed.
#
# find's '-prune' functionality is implemented by testing the command's exit
# status. If the command indicated exits with status 1 for a directory, this
# means: do not traverse the directory in question. For other types of files,
# exit status 1 is the same as 0 (success). Exit status 2 means: stop the
# execution of 'traverse' and resume program execution. An exit status greater
# than 2 indicates system failure and causes the program to abort.
#
# find's '-depth' functionality is implemented using the -d option. By default,
# 'traverse' handles directories first, before their contents. The -d option
# causes depth-first traversal, so all entries in a directory will be acted on
# before the directory itself. This applies recursively to subdirectories. That
# means depth-first traversal is incompatible with pruning, so returning status
# 1 for directories will have no effect.
#
# Inspired by myfind() in Rich's sh tricks, but much improved and extended
# (no forking of subshells, no change of working directory, pruning,
# depth-first traversal, failure handling).
#
# --- begin license ---
# Copyright (c) 2016 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# --- end license ---

# TODO: implement option to call handler function with multiple arguments

traverse() {
	unset -v _Msh_trVo_d
	while startswith "${1-}" '-'; do
		case $1 in
		( -d )	_Msh_trVo_d=y ;;
		( -- )	shift; break ;;
		( -* )	die "traverse: invalid option: $1" || return ;;
		( * )	break ;;
		esac
		shift
	done
	eq "$#" 2 || die "traverse: exactly 2 non-option arguments expected, got $#" || return
	is present "$1" || die "traverse: file not found: $1" || return
	command -v "$2" >/dev/null || die "traverse: command not found: $2" || return
	if isset _Msh_trVo_d; then
		if is -L dir "$1"; then
			_Msh_trV_C=$2
			_Msh_doTraverse "$1"
		fi
		"$2" "$1"
		case $? in
		( 0|1|2 ) ;;
		( * )	die "traverse -d: command failed with status $?: $2" ;;
		esac
	else
		"$2" "$1"
		case $? in
		( 0 )	if is -L dir "$1"; then
				_Msh_trV_C=$2
				_Msh_doTraverse "$1"
				eval "unset -v _Msh_trV_F _Msh_trV_C _Msh_trVo_d; return $?"
			fi ;;
		( 1|2 )	;;
		( * )	die "traverse: command failed with status $?: $2" ;;
		esac
	fi
}

if thisshellhas BUG_UPP; then
	_Msh_doTraverse() {
		_Msh_trV_F=$1
		case $- in
		( *f* )	set +f
			set -- "${_Msh_trV_F}"/*
			is present "$1" || shift
			set -- "${_Msh_trV_F}"/.[!.]* ${1+"$@"}
			is present "$1" || shift
			set -- "${_Msh_trV_F}"/..?* ${1+"$@"}
			is present "$1" || shift
			set -f ;;
		( * )	set -- "${_Msh_trV_F}"/*
			is present "$1" || shift
			set -- "${_Msh_trV_F}"/.[!.]* ${1+"$@"}
			is present "$1" || shift
			set -- "${_Msh_trV_F}"/..?* ${1+"$@"}
			is present "$1" || shift ;;
		esac
		if isset _Msh_trVo_d; then
			while let "$#"; do
				if is dir "$1"; then
					_Msh_doTraverse "$1" || return
				fi
				"${_Msh_trV_C}" "$1"
				case $? in
				( 0|1 )	;;
				( 2 )	return 2 ;;
				( * )	die "traverse -d: command failed with status $?: ${_Msh_trV_C}" || return ;;
				esac
				shift
			done
		else
			while let "$#"; do
				"${_Msh_trV_C}" "$1"
				case $? in
				( 0 )	if is dir "$1"; then
						_Msh_doTraverse "$1" || return
					fi ;;
				( 1 )	;;
				( 2 )	return 2 ;;
				( * )	die "traverse: command failed with status $?: ${_Msh_trV_C}" || return ;;
				esac
				shift
			done
		fi
	}
else
	# no BUG_UPP: normal version
	_Msh_doTraverse() {
		_Msh_trV_F=$1
		case $- in
		( *f* )	set +f
			set -- "${_Msh_trV_F}"/*
			is present "$1" || shift
			set -- "${_Msh_trV_F}"/.[!.]* "$@"
			is present "$1" || shift
			set -- "${_Msh_trV_F}"/..?* "$@"
			is present "$1" || shift
			set -f ;;
		( * )	set -- "${_Msh_trV_F}"/*
			is present "$1" || shift
			set -- "${_Msh_trV_F}"/.[!.]* "$@"
			is present "$1" || shift
			set -- "${_Msh_trV_F}"/..?* "$@"
			is present "$1" || shift ;;
		esac
		if isset _Msh_trVo_d; then
			while let "$#"; do
				if is dir "$1"; then
					_Msh_doTraverse "$1" || return
				fi
				"${_Msh_trV_C}" "$1"
				case $? in
				( 0|1 )	;;
				( 2 )	return 2 ;;
				( * )	die "traverse -d: command failed with status $?: ${_Msh_trV_C}" || return ;;
				esac
				shift
			done
		else
			while let "$#"; do
				"${_Msh_trV_C}" "$1"
				case $? in
				( 0 )	if is dir "$1"; then
						_Msh_doTraverse "$1" || return
					fi ;;
				( 1 )	;;
				( 2 )	return 2 ;;
				( * )	die "traverse: command failed with status $?: ${_Msh_trV_C}" || return ;;
				esac
				shift
			done
		fi
	}
fi

if thisshellhas ROFUNC; then
	readonly -f traverse _Msh_doTraverse
fi