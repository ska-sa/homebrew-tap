require 'formula'

class Tigger < Formula
  homepage 'http://www.astron.nl/meqwiki/Tigger'
  url 'https://svn.astron.nl/Tigger/release/Tigger/release-1.2.2'
  head 'https://svn.astron.nl/Tigger/trunk/Tigger'

  depends_on 'pyqwt'
  depends_on 'purr'
  depends_on 'pyfits' => :python
  depends_on 'numpy' => :python
  depends_on 'scipy' => :python
  depends_on 'astLib' => :python

  def patches
    # Ignore setAllowX11ColorNames attribute on non-X11 Mac platform
    # Fix imports to be absolute
    DATA
  end

  def install
    tigger = "#{lib}/#{which_python}/site-packages/Tigger"
    mkdir_p ["#{tigger}", "#{share}/doc", "#{share}/meqtrees"]
    cp_r '.', "#{tigger}/"
    rm_rf ["#{tigger}/bin", "#{tigger}/doc", "#{tigger}/icons"]
    cp_r 'bin', "#{bin}"
    rm_f "#{bin}/tigger"
    ln_s "#{tigger}/tigger", "#{bin}/tigger"
    cp_r 'doc', "#{share}/doc/tigger"
    cp_r 'icons', "#{share}/meqtrees/"
  end

  def caveats; <<-EOS.undent
    For non-homebrew Python, you need to amend your PYTHONPATH like so:
      export PYTHONPATH=#{HOMEBREW_PREFIX}/lib/#{which_python}/site-packages:$PYTHONPATH
    EOS
  end

  def which_python
    "python" + `python -c 'import sys;print(sys.version[:3])'`.strip
  end

  def test
    if system 'python -c "import Tigger"' then
      onoe 'Tigger FAILED'
    else
      ohai 'Tigger OK'
    end
  end
end

__END__
diff --git a/Models/PlotStyles.py b/Models/PlotStyles.py
index 19cdf96..2cda4a7 100644
--- a/Models/PlotStyles.py
+++ b/Models/PlotStyles.py
@@ -45,7 +45,11 @@ StyleAttributeTypes = dict(symbol_size=int,symbol_linewidth=int,label_size=int);
 # list of known colors
 ColorList = [ "black","blue","lightblue","green","lightgreen","cyan","red","orange red","purple","magenta","yellow","white" ];
 DefaultColor = "black";
-QColor.setAllowX11ColorNames(True);
+# Ignore this (non-existent) attribute on non-X11 platforms like the Mac
+try:
+    QColor.setAllowX11ColorNames(True);
+except AttributeError:
+    pass
 
 # dict and method to pick a contrasting color (i.e. suitable as background for specified color)
 ContrastColor = dict(white="#404040",yellow="#404040");
diff --git a/Images/ControlDialog.py b/Images/ControlDialog.py
index 856b7c5..0f5e0b6 100644
--- a/Images/ControlDialog.py
+++ b/Images/ControlDialog.py
@@ -37,7 +37,7 @@ import Kittens.utils
 from Kittens.utils import curry,PersistentCurrier
 from Kittens.widgets import BusyIndicator
 
-from Images import SkyImage,Colormaps
+from Tigger.Images import SkyImage,Colormaps
 from Tigger import pixmaps
 from Tigger.Widgets import FloatValidator,TiggerPlotCurve,TiggerPlotMarker
 
diff --git a/Images/Controller.py b/Images/Controller.py
index 1af776e..ea1b46c 100644
--- a/Images/Controller.py
+++ b/Images/Controller.py
@@ -42,15 +42,15 @@ _verbosity = Kittens.utils.verbosity(name="imagectl");
 dprint = _verbosity.dprint;
 dprintf = _verbosity.dprintf;
 
-from Images import SkyImage,Colormaps
-from Models import ModelClasses,PlotStyles
-from Coordinates import Projection,radec_string;
-from Models.SkyModel import SkyModel
+from Tigger.Images import SkyImage,Colormaps
+from Tigger.Models import ModelClasses,PlotStyles
+from Tigger.Coordinates import Projection,radec_string;
+from Tigger.Models.SkyModel import SkyModel
 from Tigger import pixmaps
 from Tigger.Widgets import FloatValidator
 
-from RenderControl import RenderControl
-from ControlDialog import ImageControlDialog
+from Tigger.Images.RenderControl import RenderControl
+from Tigger.Images.ControlDialog import ImageControlDialog
 
 class ImageController (QFrame):
   """An ImageController is a widget for controlling the display of one image.
diff --git a/Images/Manager.py b/Images/Manager.py
index 0168c5a..240bfd3 100644
--- a/Images/Manager.py
+++ b/Images/Manager.py
@@ -38,9 +38,9 @@ import Kittens.utils
 from Kittens.utils import curry,PersistentCurrier
 from Kittens.widgets import BusyIndicator
 
-from Controller import ImageController,dprint,dprintf
+from Tigger.Images.Controller import ImageController,dprint,dprintf
 
-import SkyImage
+from Tigger.Images import SkyImage
 from Tigger.Images import  FITS_ExtensionList
 
 class ImageManager (QWidget):
diff --git a/Images/RenderControl.py b/Images/RenderControl.py
index def7906..5ccab51 100644
--- a/Images/RenderControl.py
+++ b/Images/RenderControl.py
@@ -41,7 +41,7 @@ _verbosity = Kittens.utils.verbosity(name="rc");
 dprint = _verbosity.dprint;
 dprintf = _verbosity.dprintf;
 
-from Images import SkyImage,Colormaps
+from Tigger.Images import SkyImage,Colormaps
 from Tigger import pixmaps,ConfigFile
 from Tigger.Widgets import FloatValidator
 
diff --git a/Images/SkyImage.py b/Images/SkyImage.py
index 889896c..f2c9fed 100644
--- a/Images/SkyImage.py
+++ b/Images/SkyImage.py
@@ -40,8 +40,8 @@ import Kittens.utils
 pyfits = Kittens.utils.import_pyfits();
 
 from Tigger.Coordinates import Projection
-import Colormaps
-import FITSHeaders
+from Tigger.Images import Colormaps
+from Tigger.Images import FITSHeaders
 
 DEG = math.pi/180;
 
diff --git a/SkyModelTreeWidget.py b/SkyModelTreeWidget.py
index 0fc57e3..d0800f4 100644
--- a/SkyModelTreeWidget.py
+++ b/SkyModelTreeWidget.py
@@ -32,8 +32,8 @@ import Kittens.utils
 from Kittens.utils import PersistentCurrier
 from Kittens.widgets import BusyIndicator
 
-from Models import ModelClasses,PlotStyles
-from Models.SkyModel import SkyModel
+from Tigger.Models import ModelClasses,PlotStyles
+from Tigger.Models.SkyModel import SkyModel
 
 _verbosity = Kittens.utils.verbosity(name="tw");
 dprint = _verbosity.dprint;
diff --git a/Plot/SkyModelPlot.py b/Plot/SkyModelPlot.py
index 4654614..7ce79f9 100644
--- a/Plot/SkyModelPlot.py
+++ b/Plot/SkyModelPlot.py
@@ -43,12 +43,11 @@ dprintf = _verbosity.dprintf;
 
 from Tigger import pixmaps,Config,ConfigFile
 from Tigger.Models import ModelClasses,PlotStyles
-import Coordinates
-from Coordinates import Projection
-from  Models.SkyModel import SkyModel
-import MainWindow
+from Tigger import Coordinates
+from Tigger.Coordinates import Projection
+from Tigger.Models.SkyModel import SkyModel
 from Tigger.Widgets import TiggerPlotCurve,TiggerPlotMarker
-import MouseModes
+from Tigger.Plot import MouseModes
 
 # plot Z depths for various classes of objects
 Z_Image = 1000;
