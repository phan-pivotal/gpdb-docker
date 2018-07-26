tmux new-window docker run -i -p 5432:5432 penghan/pub:gpdb-docker-5.9.0\; split-window -h -d \;
tmux new-window docker run -i -p 6432:5432 penghan/pub:gpdb-docker-5.9.0\; split-window -d\; attach \;
