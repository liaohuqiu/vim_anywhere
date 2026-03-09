#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
vhash-vscode-ext.py - CLI for building and reinstalling VHash VSCode extension.
---
VHash VSCode 扩展构建与重装命令行工具。
"""

import logging
import time
from pathlib import Path

from cpbox.tool import functocli
from cpbox.tool import serde

logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')
logger = logging.getLogger()


class PathInfo:

    def __init__(self, ext_dir, install_for_cursor=True, install_for_default_profile=True):
        self.ext_dir = Path(ext_dir)
        self.install_for_cursor = install_for_cursor
        self.install_for_default_profile = install_for_default_profile
        self.user_data_dir = None
        self.profiles_dir = None
        self.default_settings_path = None
        self.extensions_dir = None
        self.cli = None

    def detect(self):
        cli = 'code'
        if self.install_for_cursor:
            user_data_dir = Path('~/Library/Application Support/Cursor/User').expanduser()
            extensions_dir = Path('~/.cursor/extensions').expanduser()
            app_cli = Path('/Applications/Cursor.app/Contents/Resources/app/bin/cursor')
            if app_cli.exists():
                cli = str(app_cli)
            else:
                user_cli = Path('~/.local/bin/cursor').expanduser()
                if user_cli.exists():
                    cli = str(user_cli)
                else:
                    cli = None
        else:
            user_data_dir = Path('~/Library/Application Support/Code/User').expanduser()
            extensions_dir = Path('~/.vscode/extensions').expanduser()

        profiles_dir = user_data_dir / 'profiles'
        default_settings_path = user_data_dir / 'settings.json'

        self.user_data_dir = user_data_dir
        self.profiles_dir = profiles_dir
        self.default_settings_path = default_settings_path
        self.extensions_dir = extensions_dir
        self.cli = cli

        logger.info('user_data_dir=%s', self.user_data_dir)
        logger.info('profiles_dir=%s', self.profiles_dir)
        logger.info('default_settings_path=%s', self.default_settings_path)
        logger.info('extensions_dir=%s', self.extensions_dir)
        logger.info('cli=%s', self.cli)
        return self

    def list_all_profiles(self, include_default=False):
        profile_map = {}
        storage_path = self.user_data_dir / 'globalStorage' / 'storage.json'
        storage = {}
        if storage_path.exists():
            storage = serde.load_json_file(storage_path, fallback={})
        else:
            logger.warning('storage.json not found: %s', storage_path)
        storage_profiles = storage.get('userDataProfiles', []) or []

        if storage_profiles:
            for item in storage_profiles:
                profile_id = str(item.get('location') or '').strip()
                if not profile_id or profile_id == '__default__profile__':
                    continue
                profile_name = str(item.get('name') or '').strip() or profile_id
                profile_map[profile_id] = {
                    'id': profile_id,
                    'name': profile_name,
                    'settings_path': str(self.profiles_dir / profile_id / 'settings.json'),
                    'extensions_json_path': str(self.profiles_dir / profile_id / 'extensions.json'),
                    'is_default': False
                }

        profiles = sorted(profile_map.values(), key=lambda x: x['name'])
        if include_default:
            profiles.insert(0, {
                'id': '__default__profile__',
                'name': 'Default',
                'settings_path': str(self.default_settings_path),
                'extensions_json_path': str(self.default_settings_path.parent / 'extensions.json'),
                'is_default': True
            })

        logger.info('all_profiles=\n%s', serde.pjson(profiles))
        return profiles

    def cli_cmd_or_exit(self):
        if self.install_for_cursor and not self.cli:
            logger.warning('cursor not found, install_for_cursor=true')
            raise SystemExit(1)
        return f'"{self.cli}"' if self.cli else 'code'


class App(functocli.BaseCliApp):

    def __init__(self, install_for_cursor=True, install_for_default_profile=True):
        functocli.BaseCliApp.__init__(self)
        self._ext_dir = self.cli_root_dir
        self.path_info = PathInfo(
            ext_dir=self._ext_dir,
            install_for_cursor=install_for_cursor,
            install_for_default_profile=install_for_default_profile
        ).detect()
        logger.info('ext_dir=%s', self._ext_dir)

    def _run(self, cmd, cwd=None):
        work_dir = cwd or self._ext_dir
        self.shell_run(f'cd \"{work_dir}\" && {cmd}')

    def _load_package_info(self):
        pkg_path = self._ext_dir / 'package.json'
        logger.info('load package: %s', pkg_path)
        pkg = serde.load_json_file(pkg_path, fallback=None)
        if pkg is None:
            logger.error('failed to load package json: %s', pkg_path)
            return None
        publisher = pkg.get('publisher', 'local')
        name = pkg.get('name', 'vhash-vscode-ext')
        version = pkg.get('version', '0.0.1')
        return {
            'publisher': publisher,
            'name': name,
            'version': version,
            'extension_id': f'{publisher}.{name}'
        }

    def _find_vsix(self):
        vsix_list = sorted(self._ext_dir.glob('*.vsix'), key=lambda p: p.stat().st_mtime, reverse=True)
        if not vsix_list:
            raise FileNotFoundError('No VSIX file found in extension directory')
        logger.info('vsix: %s', vsix_list[0])
        return vsix_list[0]

    def _upsert_keybinding(self, items, binding):
        before = binding.get('before', [])
        updated = False
        new_items = []
        for item in items:
            if item.get('before') == before:
                new_items.append(binding)
                updated = True
            else:
                new_items.append(item)
        if not updated:
            new_items.append(binding)
        logger.info('keybinding_updated=%s', updated)
        return new_items

    def _bind_vim_key_for_settings_path(self, settings_path):
        settings_path = Path(settings_path)
        if not settings_path.exists():
            logger.warning('settings.json not found, skip: %s', settings_path)
            return
        logger.info('bind settings: %s', settings_path)
        settings = serde.load_json_file(settings_path, fallback=None)
        if settings is None:
            raise RuntimeError(f'failed to load settings json: {settings_path}')

        binding = {
            'before': [',', 'c', 'n'],
            'commands': ['vhashTools.copySelectionPathRange']
        }

        normal_key = 'vim.normalModeKeyBindingsNonRecursive'
        visual_key = 'vim.visualModeKeyBindingsNonRecursive'

        normal_list = settings.get(normal_key, [])
        visual_list = settings.get(visual_key, [])

        settings[normal_key] = self._upsert_keybinding(normal_list, binding)
        settings[visual_key] = self._upsert_keybinding(visual_list, binding)

        serde.dump_json_file(settings_path, settings)
        logger.info('bind done: %s', settings_path)

    def list_all_profiles(self, include_default=False):
        profiles = self.path_info.list_all_profiles(include_default=include_default)
        return serde.pjson(profiles)

    def _upsert_profile_extension(self, extensions_path, package_info):
        ext_id = package_info['extension_id']
        version = package_info['version']
        ext_dir = self.path_info.extensions_dir / f'{ext_id}-{version}'
        extensions_path = Path(extensions_path)
        logger.info('extensions_json=%s', extensions_path)

        data = []
        if extensions_path.exists():
            data = serde.load_json_file(extensions_path, fallback=None)
            if data is None:
                raise RuntimeError(f'failed to load extensions json: {extensions_path}')

        entry = {
            'identifier': {'id': ext_id},
            'version': version,
            'location': {'$mid': 1, 'path': str(ext_dir), 'scheme': 'file'},
            'relativeLocation': f'{ext_id}-{version}',
            'metadata': {
                'installedTimestamp': int(time.time() * 1000),
                'source': 'vsix',
                'id': ext_id,
                'publisherDisplayName': 'local',
                'targetPlatform': 'universal',
                'updated': False,
                'private': False,
                'isPreReleaseVersion': False,
                'hasPreReleaseVersion': False
            }
        }

        updated = False
        new_data = []
        for item in data:
            if item.get('identifier', {}).get('id') == ext_id:
                new_data.append(entry)
                updated = True
            else:
                new_data.append(item)
        if not updated:
            new_data.append(entry)

        serde.dump_json_file(extensions_path, new_data)
        logger.info('extensions_json_updated=%s', updated)

    def _remove_profile_extension(self, extensions_path, package_info):
        ext_id = package_info['extension_id']
        extensions_path = Path(extensions_path)
        if not extensions_path.exists():
            logger.info('extensions_json_missing_skip=%s', extensions_path)
            return

        data = serde.load_json_file(extensions_path, fallback=None)
        if data is None:
            raise RuntimeError(f'failed to load extensions json: {extensions_path}')

        new_data = [item for item in data if item.get('identifier', {}).get('id') != ext_id]
        if len(new_data) == len(data):
            logger.info('extensions_json_no_change=%s', extensions_path)
            return

        serde.dump_json_file(extensions_path, new_data)
        logger.info('extensions_json_removed=%s', extensions_path)

    def npm_install(self):
        self._run('npm install')

    def build(self):
        self.npm_install()
        self._run('npm run compile')

    def package(self):
        self._run('npx @vscode/vsce package')

    def setup_all_profiles(self, vsix=None, include_default=True):
        package_info = self._load_package_info()
        if package_info is None:
            logger.error('package info not available, abort setup_all_profiles')
            raise SystemExit(-1)

        if vsix is None:
            vsix = self._find_vsix()
        install_cmd = self.path_info.cli_cmd_or_exit()
        self._run(f'{install_cmd} --install-extension "{vsix}"', cwd=self._ext_dir)

        profiles = self.path_info.list_all_profiles(include_default=include_default)
        for profile in profiles:
            logger.info('setup_profile: %s', profile['name'])
            self._bind_vim_key_for_settings_path(profile['settings_path'])
            if not profile.get('is_default'):
                self._upsert_profile_extension(profile['extensions_json_path'], package_info=package_info)

    def uninstall(self):
        package_info = self._load_package_info()
        if package_info is None:
            logger.error('package info not available, abort uninstall')
            raise SystemExit(-1)

        ext_id = package_info['extension_id']
        install_cmd = self.path_info.cli_cmd_or_exit()
        self._run(f'{install_cmd} --uninstall-extension {ext_id} || true', cwd=self._ext_dir)
        profiles = self.path_info.list_all_profiles(include_default=True)
        for profile in profiles:
            self._remove_profile_extension(profile['extensions_json_path'], package_info=package_info)

    def reinstall(self):
        self.uninstall()
        self.setup_all_profiles()

    def do_all(self):
        self.build()
        self.package()
        self.reinstall()


if __name__ == '__main__':
    functocli.run_app(App, default_method='help')
