#!/usr/bin/env python3
"""Exercise all original shaders on a real macOS OpenGL context, without AppKit."""
import pathlib, re, subprocess, tempfile
root=pathlib.Path(__file__).resolve().parents[2]
with tempfile.TemporaryDirectory(prefix='peon-shaders-') as temporary:
    output=pathlib.Path(temporary)
    binary=output/'check-shaders'
    subprocess.run(['xcrun','clang','-Wno-deprecated-declarations','-framework','OpenGL',str(root/'mac/tests/shaders.m'),'-o',str(binary)],check=True)
    shaders=[]
    uniforms=''.join('uniform '+type_+' '+name+';\n' for type_,name in [('mat4','CC_PMatrix'),('mat4','CC_MVMatrix'),('mat4','CC_MVPMatrix'),('vec4','CC_Time'),('vec4','CC_SinTime'),('vec4','CC_CosTime'),('vec4','CC_Random01')])
    for header in sorted((root/'rover/cocos2d').glob('ccShader_*.h')):
        source=header.read_text().split('*/',1)[1].strip()
        source=source[1:source.rfind('"')]
        source=re.sub(r'\\n\\\n','\n',source)
        # Same desktop adaptation as CCGLProgram.m.
        source=source.replace('#extension GL_OES_standard_derivatives : enable','')
        shader=output/(header.stem+'.glsl');shader.write_text(uniforms+source);shaders.append(str(shader))
    subprocess.run([str(binary),*shaders],check=True)
