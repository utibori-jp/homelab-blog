# homelab-blog

HUGO     ?= hugo
PORT     ?= 1313
CHECKDIR := .hugo_check

.DEFAULT_GOAL := help
.PHONY: help serve serve-prod build check clean new

serve: ## 下書き込みでプレビュー → http://localhost:1313/
	$(HUGO) server -D --disableFastRender --navigateToChanged --bind 0.0.0.0 -p $(PORT) -O

serve-prod: ## 公開時と同じ設定でプレビュー（下書きは出ない）
	$(HUGO) server --environment production --disableFastRender --bind 0.0.0.0 -p $(PORT) -O

build: ## 本番ビルド（public/ に出力）
	$(HUGO) --gc --minify --logLevel info

check: ## 下書きを含めてビルドが通るか確認（出力は捨てる）
	@$(HUGO) -D --gc --logLevel warn --destination $(CHECKDIR)
	@rm -rf $(CHECKDIR)
	@echo "OK"

clean: ## public/ などの生成物を削除
	rm -rf public resources/_gen $(CHECKDIR)

new: ## 記事を新規作成: make new POST=e-estonia-series/foo
ifndef POST
	$(error POST を指定してほしい。例: make new POST=e-estonia-series/foo)
endif
	$(HUGO) new content posts/$(POST)/index.md
