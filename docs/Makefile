
# Makefile for Latex specsheet documentation
#

# You can set these variables from the command line.
PAPER         =
BUILDDIR      = refman
MAKE 					= make -f Makefile

# Internal variables.
PAPEROPT_a4     = -D latex_paper_size=a4
PAPEROPT_letter = -D latex_paper_size=letter

.PHONY: latexpdf clean

clean:
	rm -rf $(BUILDDIR)/*.pdf

latexpdf:
	@echo "Running LaTeX files through pdflatex..."
	#mkdir build
	$(MAKE) -C ./$(BUILDDIR) all-pdf
	@echo "pdflatex finished; the PDF files are in $(BUILDDIR)."
