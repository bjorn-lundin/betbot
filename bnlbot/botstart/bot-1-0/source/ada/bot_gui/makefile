all: bot_gui img/bnl img/jmb

img/bnl : 
	ln -s $(BOT_START)/user/bnl/gui_related img/bnl

img/jmb : 
	ln -s $(BOT_START)/user/jmb/gui_related img/jmb
    
bot_gui:
	cd src && gprbuild -p -Pbot_gui.gpr

clean:
	cd src && gprclean -Pbot_gui.gpr
