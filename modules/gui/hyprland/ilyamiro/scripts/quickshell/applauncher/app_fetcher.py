#!/usr/bin/env python3
import os
import glob
import json

def app_dirs():
    home = os.path.expanduser('~')
    user = os.environ.get("USER") or os.path.basename(home)
    dirs = [
        f'{home}/.local/share/applications',
        '/usr/local/share/applications',
        '/usr/share/applications',
        '/var/lib/flatpak/exports/share/applications',
        f'{home}/.local/share/flatpak/exports/share/applications',
        f'{home}/.nix-profile/share/applications',
        f'{home}/.local/state/nix/profile/share/applications',
        f'/etc/profiles/per-user/{user}/share/applications',
        '/run/current-system/sw/share/applications',
    ]

    for data_dir in os.environ.get("XDG_DATA_DIRS", "").split(":"):
        if data_dir:
            dirs.append(os.path.join(data_dir, "applications"))

    seen = set()
    return [d for d in dirs if not (d in seen or seen.add(d))]

def fetch_apps():
    apps = {}
    
    for d in app_dirs():
        if not os.path.exists(d):
            continue
            
        for f in glob.glob(os.path.join(d, '**/*.desktop'), recursive=True):
            try:
                with open(f, 'r', encoding='utf-8') as file:
                    app = {'name': '', 'exec': '', 'icon': '', 'search': ''}
                    is_desktop = False
                    no_display = False
                    search_terms = []
                    
                    for line in file:
                        line = line.strip()
                        if line == '[Desktop Entry]':
                            is_desktop = True
                        elif line.startswith('['):
                            is_desktop = False
                            
                        if is_desktop:
                            if line.startswith('Name=') and not app['name']:
                                app['name'] = line[5:]
                            elif line.startswith('Exec=') and not app['exec']:
                                # Strip %u, %f, and @@ placeholders
                                app['exec'] = line[5:].split(' %')[0].split(' @@')[0]
                            elif line.startswith('Icon=') and not app['icon']:
                                app['icon'] = line[5:]
                            elif line.startswith('GenericName='):
                                search_terms.append(line[12:])
                            elif line.startswith('Keywords='):
                                search_terms.extend(line[9:].split(';'))
                            elif line.startswith('Categories='):
                                search_terms.extend(line[11:].split(';'))
                            elif line.startswith('NoDisplay=true') or line.startswith('NoDisplay=1'):
                                no_display = True
                                
                    if app['name'] and app['exec'] and not no_display:
                        app['search'] = ' '.join(
                            term for term in [app['name'], *search_terms] if term
                        )
                        apps[app['name']] = app
            except Exception:
                pass
                
    # Sort alphabetically and return as JSON
    res = list(apps.values())
    res.sort(key=lambda x: x['name'].lower())
    print(json.dumps(res))

if __name__ == "__main__":
    fetch_apps()
