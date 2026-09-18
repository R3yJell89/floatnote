#target premierepro
/**
 * FloatNote Adobe Premiere Pro Integration Script (ExtendScript)
 * ==============================================================
 * Экспорт маркеров активного секвенса Premiere Pro 
 * в чеклист FloatNote (~/Library/Application Support/FloatNote/checklist.json).
 */

(function() {
    function getFloatNotePath() {
        var home = Folder.myDocuments.parent.fsName;
        return home + "/Library/Application Support/FloatNote/checklist.json";
    }

    function syncMarkersToFloatNote() {
        var seq = app.project.activeSequence;
        if (!seq) {
            alert("FloatNote: Откройте таймлайн (секвенс) в Adobe Premiere Pro!");
            return;
        }

        var markers = seq.markers;
        if (!markers || markers.numMarkers === 0) {
            alert("FloatNote: На текущем таймлайне Premiere Pro нет маркеров.");
            return;
        }

        var jsonPath = getFloatNotePath();
        var file = new File(jsonPath);
        var existing = [];

        if (file.exists) {
            file.open("r");
            var content = file.read();
            file.close();
            try {
                existing = JSON.parse(content);
            } catch (e) {
                existing = [];
            }
        }

        var existingTexts = {};
        for (var i = 0; i < existing.length; i++) {
            if (existing[i] && existing[i].text) {
                existingTexts[existing[i].text] = true;
            }
        }

        var addedCount = 0;
        var currentMarker = markers.getFirstMarker();

        while (currentMarker) {
            var timecodeStr = currentMarker.start.toTimecode(seq.timebase);
            var name = currentMarker.name || "Маркер";
            var comments = currentMarker.comments || "";
            
            var text = "[" + timecodeStr + "] " + name + (comments ? " — " + comments : "");

            if (!existingTexts[text]) {
                existing.push({
                    "id": "pr-" + new Date().getTime() + "-" + Math.floor(Math.random() * 10000),
                    "text": text,
                    "isCompleted": false
                });
                existingTexts[text] = true;
                addedCount++;
            }

            currentMarker = markers.getNextMarker(currentMarker);
        }

        var folder = file.parent;
        if (!folder.exists) {
            folder.create();
        }

        file.encoding = "UTF-8";
        file.open("w");
        file.write(JSON.stringify(existing, null, 2));
        file.close();

        alert("FloatNote: Успешно экспортировано " + addedCount + " маркеров из Premiere Pro в FloatNote!");
    }

    syncMarkersToFloatNote();
})();
