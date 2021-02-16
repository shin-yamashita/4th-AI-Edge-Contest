//
// 2012/09/  plt plot graph
//

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <ctype.h>
#include <string.h>

#include "Grp.h"
#define min(x,y)	(x>y?y:x)
#define max(x,y)	(x>y?x:y)

int debug = 0;
int nplt = 0;
int autoscale = 1;
double xmin = 0.0, xmax = 0.0, ymin = 0.0, ymax = 0.0;

static int plot(char *str)
{
        char *tok, *tok2, sfn[80];
	static double yd, time = 0, T = 10e-3;
                
	if(debug) fputs(str, stderr); 
	tok = strtok(str, "\n");
	if(tok){
	  if(*tok == ':'){
		switch(tok[1]){
		case 't': g_set_title(0, &tok[2]);      break;
		case 'T': T = atof(&tok[2]);            break;
		case 'x': g_set_xlabel(0, &tok[2]);     break;
		case 'y': g_set_ylabel(0, &tok[2]);     break;
		case 'Y':
			tok = strtok(str, " \n");
			tok = strtok(NULL, " \n");
			if(tok) ymin = atof(tok); 
			tok = strtok(NULL, " \n");
			if(tok) ymax = atof(tok); 
			autoscale = 0;
			break;
		case 'l':
			tok = strtok(&tok[2], " \n");
			if(tok){
				tok2 = strtok(NULL, " \n");
				if(tok2) g_set_legend(0, atoi(tok), tok2);
			}
			break;
		case 'c': time = 0; g_clear();  break;
		case 'v':
			g_set_scale(0, 0.0, time, ymin, ymax);
			g_view_page(0);
			sprintf(sfn, "rplot-%d.dat", nplt++);
			nplt = nplt % 10;
			g_save("lin", sfn);
			return 1;
		case 's': break;
		}
	  }else if(*tok == '$'){
		int ln = 0;
		tok = strtok(str, " \n");
		while((tok = strtok(NULL, " \n"))){
			yd = atoi(tok);
			g_plotm(time, yd, ln++);
			if(autoscale){
				ymin = min(yd, ymin);
				ymax = max(yd, ymax);
			}
		}
		time += T;
	  }else if(*tok == ' '){
		g_text(0.1, 0.9, tok);
	  }
	}
	return 0;
}

int main(int argc, char *argv[])
{
	char rxbuf[2001];
	FILE *fp = fopen("rsave-0.dat", "w");

	while(fgets(rxbuf, 2000, stdin)){
		fputs(rxbuf, fp);
		if(plot(rxbuf)){
			fclose(fp);
			sprintf(rxbuf, "rsave-%d.dat", nplt);
			fp = fopen(rxbuf, "w");
		}
	}
	return 0;
}
