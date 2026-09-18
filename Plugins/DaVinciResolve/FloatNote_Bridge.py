#!/usr/bin/env python3
"""
FloatNote DaVinci Resolve Plugin & Bridge
=========================================
Официальный мост и плагин для DaVinci Resolve Studio & Free.

Возможности:
1. Запуск из DaVinci Resolve (меню Workspace -> Scripts -> FloatNote_Bridge)
   - Экспорт маркеров таймлайна DaVinci в чеклист FloatNote.
   - Импорт задач чеклиста FloatNote в виде маркеров на таймлайн DaVinci.
2. Использование из командной строки / внешнего софта:
   - python3 FloatNote_Bridge.py info
   - python3 FloatNote_Bridge.py get_tc
   - python3 FloatNote_Bridge.py jump <timecode>
   - python3 FloatNote_Bridge.py marker <timecode> <color> <name> [note]
   - python3 FloatNote_Bridge.py sync_markers
"""

import sys
import os
import json
import uuid

# Auto-configure DaVinci Resolve Scripting environment
RESOLVE_SCRIPT_PATHS = [
    "/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/Scripting/Modules",
    os.path.expanduser("~/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/Scripting/Modules")
]

for p in RESOLVE_SCRIPT_PATHS:
    if os.path.exists(p) and p not in sys.path:
        sys.path.append(p)

FLOATNOTE_SUPPORT_DIR = os.path.expanduser("~/Library/Application Support/FloatNote")
CHECKLIST_PATH = os.path.join(FLOATNOTE_SUPPORT_DIR, "checklist.json")

def get_bmd_resolve():
    """Подключение к запущенному DaVinci Resolve"""
    try:
        import DaVinciResolveScript as bmd
        resolve = bmd.scriptapp("Resolve")
        if resolve is None:
            # Try fusion
            fusion = bmd.scriptapp("Fusion")
            if fusion:
                resolve = fusion.GetResolve()
        return resolve
    except Exception as e:
        return None

def tc_to_frames(tc_str, fps):
    clean = tc_str.replace(";", ":").strip()
    parts = [int(p) for p in clean.split(":")]
    if len(parts) == 4:
        h, m, s, f = parts
        return int((h * 3600 + m * 60 + s) * fps + f)
    return 0

def frames_to_tc(frames, fps):
    total_sec = int(frames / fps)
    f = int(frames % fps)
    s = total_sec % 60
    m = (total_sec // 60) % 60
    h = total_sec // 3600
    return f"{h:02d}:{m:02d}:{s:02d}:{f:02d}"

def cmd_info(resolve):
    if not resolve:
        print(json.dumps({"success": False, "error": "DaVinci Resolve is not running"}))
        return
    pm = resolve.GetProjectManager()
    project = pm.GetCurrentProject() if pm else None
    timeline = project.GetCurrentTimeline() if project else None
    
    data = {
        "success": True,
        "project": project.GetName() if project else None,
        "timeline": timeline.GetName() if timeline else None,
        "timecode": timeline.GetCurrentTimecode() if timeline else None
    }
    print(json.dumps(data, ensure_ascii=False))

def cmd_get_tc(resolve):
    if not resolve:
        print(json.dumps({"success": False, "error": "Resolve not found"}))
        return
    pm = resolve.GetProjectManager()
    project = pm.GetCurrentProject() if pm else None
    timeline = project.GetCurrentTimeline() if project else None
    if not timeline:
        print(json.dumps({"success": False, "error": "No active timeline"}))
        return
    
    tc = timeline.GetCurrentTimecode()
    print(json.dumps({"success": True, "timecode": tc}))

def cmd_jump(resolve, target_tc):
    if not resolve:
        print(json.dumps({"success": False, "error": "Resolve not found"}))
        return
    pm = resolve.GetProjectManager()
    project = pm.GetCurrentProject() if pm else None
    timeline = project.GetCurrentTimeline() if project else None
    if not timeline:
        print(json.dumps({"success": False, "error": "No active timeline"}))
        return
    
    ok = timeline.SetCurrentTimecode(target_tc)
    print(json.dumps({"success": bool(ok), "timecode": target_tc}))

def cmd_marker(resolve, target_tc, color="Blue", name="Marker", note="FloatNote"):
    if not resolve:
        print(json.dumps({"success": False, "error": "Resolve not found"}))
        return
    pm = resolve.GetProjectManager()
    project = pm.GetCurrentProject() if pm else None
    timeline = project.GetCurrentTimeline() if project else None
    if not timeline:
        print(json.dumps({"success": False, "error": "No active timeline"}))
        return
    
    start_frame = timeline.GetStartFrame() or 0
    fps = float(timeline.GetSetting("timelineFrameRate") or 24.0)
    
    target_abs_frames = tc_to_frames(target_tc, fps)
    marker_frame = target_abs_frames - start_frame
    if marker_frame < 0:
        marker_frame = target_abs_frames
    
    ok = timeline.AddMarker(marker_frame, color, name, note, 1)
    print(json.dumps({"success": bool(ok), "marker_frame": marker_frame, "timecode": target_tc}))

def cmd_sync_markers_to_floatnote(resolve):
    """Экспорт всех маркеров текущего таймлайна в чеклист FloatNote"""
    if not resolve:
        print("Ошибка: DaVinci Resolve не запущен.")
        return
    pm = resolve.GetProjectManager()
    project = pm.GetCurrentProject() if pm else None
    timeline = project.GetCurrentTimeline() if project else None
    if not timeline:
        print("Ошибка: Нет активного таймлайна в DaVinci.")
        return
    
    markers = timeline.GetMarkers() or {}
    if not markers:
        print("На текущем таймлайне нет маркеров.")
        return
    
    start_frame = timeline.GetStartFrame() or 0
    fps = float(timeline.GetSetting("timelineFrameRate") or 24.0)
    
    new_items = []
    for frame_id, info in sorted(markers.items()):
        abs_frame = start_frame + frame_id
        tc_str = frames_to_tc(abs_frame, fps)
        name = info.get("name", "Маркер")
        note = info.get("note", "")
        full_text = f"[{tc_str}] {name}" + (f" — {note}" if note else "")
        new_items.append({
            "id": str(uuid.uuid4()),
            "text": full_text,
            "isCompleted": False
        })
    
    # Load existing checklist
    existing = []
    if os.path.exists(CHECKLIST_PATH):
        try:
            with open(CHECKLIST_PATH, "r", encoding="utf-8") as f:
                existing = json.load(f)
        except Exception:
            existing = []
    
    existing_texts = {item.get("text") for item in existing}
    added_count = 0
    for item in new_items:
        if item["text"] not in existing_texts:
            existing.append(item)
            added_count += 1
            
    os.makedirs(FLOATNOTE_SUPPORT_DIR, exist_ok=True)
    with open(CHECKLIST_PATH, "w", encoding="utf-8") as f:
        json.dump(existing, f, ensure_ascii=False, indent=2)
        
    print(f"Успешно синхронизировано {added_count} маркеров в чеклист FloatNote!")

def run_gui_prompt(resolve):
    """Интерактивное меню при запуске из DaVinci Resolve (Workspace -> Scripts)"""
    print("=" * 50)
    print("🎬 FloatNote DaVinci Bridge Plugin")
    print("=" * 50)
    
    pm = resolve.GetProjectManager()
    project = pm.GetCurrentProject() if pm else None
    timeline = project.GetCurrentTimeline() if project else None
    
    if not project or not timeline:
        print("Откройте проект и таймлайн в DaVinci Resolve.")
        return
        
    print(f"Активный проект:  {project.GetName()}")
    print(f"Активный таймлайн: {timeline.GetName()}")
    print(f"Текущий таймкод:  {timeline.GetCurrentTimecode()}")
    print("-" * 50)
    print("1. Экспорт маркеров таймлайна в чеклист FloatNote")
    print("2. Проверить статус FloatNote")
    print("=" * 50)
    
    cmd_sync_markers_to_floatnote(resolve)

def main():
    resolve = get_bmd_resolve()
    
    if len(sys.argv) == 1:
        if resolve:
            run_gui_prompt(resolve)
        else:
            print("FloatNote DaVinci Bridge:")
            print("Запустите с аргументами: info, get_tc, jump <tc>, marker <tc> <color> <name> [note], sync_markers")
        return

    action = sys.argv[1].lower()
    
    if action == "info":
        cmd_info(resolve)
    elif action == "get_tc":
        cmd_get_tc(resolve)
    elif action == "jump":
        tc = sys.argv[2] if len(sys.argv) > 2 else "01:00:00:00"
        cmd_jump(resolve, tc)
    elif action == "marker" or action == "add_marker":
        tc = sys.argv[2] if len(sys.argv) > 2 else "01:00:00:00"
        color = sys.argv[3] if len(sys.argv) > 3 else "Blue"
        name = sys.argv[4] if len(sys.argv) > 4 else "Маркер"
        note = sys.argv[5] if len(sys.argv) > 5 else "FloatNote"
        cmd_marker(resolve, tc, color, name, note)
    elif action == "sync_markers":
        cmd_sync_markers_to_floatnote(resolve)
    else:
        print(json.dumps({"success": False, "error": f"Unknown action: {action}"}))

if __name__ == "__main__":
    main()
