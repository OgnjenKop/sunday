FLUTTER_DIR := sunday_flutter

.PHONY: get analyze fmt run apk clean

get:
	cd $(FLUTTER_DIR) && flutter pub get

analyze:
	cd $(FLUTTER_DIR) && flutter analyze

fmt:
	cd $(FLUTTER_DIR) && dart format lib test

# Usage: make run DEVICE=<device_id>
run:
	cd $(FLUTTER_DIR) && flutter run $(if $(DEVICE),-d $(DEVICE),)

apk:
	cd $(FLUTTER_DIR) && flutter build apk --debug

clean:
	cd $(FLUTTER_DIR) && flutter clean

