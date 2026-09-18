#!/usr/bin/env python3
import sys
import json

# Add DaVinci Resolve scripting module paths
RESOLVE_SCRIPT_PATHS = [
    "/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/Scripting/Modules",
    "/Applications/DaVinci Resolve/DaVinci Resolve.app/Contents/Libraries/Fusion/Modules"
]
for p in RESOLVE_SCRIPT_PATHS:
    if p not in sys.path:
        sys.path.append(p)

def get_resolve():
    try:
        import DaVinciResolveScript as bmd
        return bmd.scriptapp("Resolve")
    except Exception:
        return None

def get_current_timeline(resolve):
    if not resolve:
        return None
    pm = resolve.GetProjectManager()
    if not pm:
        return None
    proj = pm.GetCurrentProject()
    if not proj:
        return None
    return proj.GetCurrentTimeline()

def tc_to_frames(tc_str, fps):
    try:
        parts = [int(p) for p in tc_str.split(':')]
        if len(parts) == 4:
            return int((parts[0] * 3600 + parts[1] * 60 + parts[2]) * fps + parts[3])
    except Exception:
        pass
    return 0

def cmd_info():
    resolve = get_resolve()
    if not resolve:
        print(json.dumps({"success": False, "error": "DaVinci Resolve not running"}))
        return
    pm = resolve.GetProjectManager()
    proj = pm.GetCurrentProject() if pm else None
    tl = proj.GetCurrentTimeline() if proj else None
    
    data = {
        "success": True,
        "project": proj.GetName() if proj else None,
        "timeline": tl.GetName() if tl else None,
        "timecode": tl.GetCurrentTimecode() if tl else None
    }
    print(json.dumps(data))

def cmd_get_tc():
    resolve = get_resolve()
    tl = get_current_timeline(resolve)
    if not tl:
        print(json.dumps({"success": False, "error": "No active timeline"}))
        return
    tc = tl.GetCurrentTimecode()
    print(json.dumps({"success": True, "timecode": tc}))

def cmd_jump(tc):
    resolve = get_resolve()
    tl = get_current_timeline(resolve)
    if not tl:
        print(json.dumps({"success": False, "error": "No active timeline"}))
        return
    res = tl.SetCurrentTimecode(tc)
    print(json.dumps({"success": res, "timecode": tc}))

def cmd_add_marker(tc, color, name, note):
    resolve = get_resolve()
    tl = get_current_timeline(resolve)
    if not tl:
        print(json.dumps({"success": False, "error": "No active timeline"}))
        return
    
    fps = float(tl.GetSetting("timelineFrameRate") or 24.0)
    start_tc = tl.GetStartTimecode()
    start_frame = tl.GetStartFrame()
    
    # Calculate target frameId
    target_frames_from_zero = tc_to_frames(tc, fps)
    start_frames_from_zero = tc_to_frames(start_tc, fps)
    frame_id = start_frame + (target_frames_from_zero - start_frames_from_zero)
    
    # Resolve marker colors: Blue, Green, Yellow, Red, Pink, Purple, Cyan, Mint, Lemon, Cocoa, Chocolate
    valid_colors = ["Blue", "Green", "Yellow", "Red", "Pink", "Purple", "Cyan", "Mint", "Lemon", "Cocoa", "Chocolate"]
    marker_color = color if color in valid_colors else "Blue"
    
    res = tl.AddMarker(int(frame_id), marker_color, name, note, 1)
    print(json.dumps({"success": res, "frameId": int(frame_id), "color": marker_color}))

def main():
    if len(sys.argv) < 2:
        print(json.dumps({"success": False, "error": "Missing command"}))
        return
    
    cmd = sys.argv[1]
    if cmd == "info":
        cmd_info()
    elif cmd == "get_tc":
        cmd_get_tc()
    elif cmd == "jump":
        if len(sys.argv) > 2:
            cmd_jump(sys.argv[2])
        else:
            print(json.dumps({"success": False, "error": "Missing timecode"}))
    elif cmd == "add_marker":
        tc = sys.argv[2] if len(sys.argv) > 2 else ""
        color = sys.argv[3] if len(sys.argv) > 3 else "Blue"
        name = sys.argv[4] if len(sys.argv) > 4 else "Заметка FloatNote"
        note = sys.argv[5] if len(sys.argv) > 5 else ""
        cmd_add_marker(tc, color, name, note)
    else:
        print(json.dumps({"success": False, "error": f"Unknown command: {cmd}"}))

if __name__ == "__main__":
    main()
