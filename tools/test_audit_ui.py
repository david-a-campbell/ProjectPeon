import json
import tempfile
import unittest
from pathlib import Path
from audit_ui import compare

class UIAuditTest(unittest.TestCase):
    def report(self, mac, iphone):
        with tempfile.TemporaryDirectory() as directory:
            a, b = Path(directory)/'mac.jsonl', Path(directory)/'iphone.jsonl'
            a.write_text('\n'.join(json.dumps(r) for r in mac))
            b.write_text('\n'.join(json.dumps(r) for r in iphone))
            return compare(a,b,0.75)

    def screen(self, axes=(48,0,0,48), origin=(0,0), name='tooltip'):
        return {'screen':name,'nodes':[{'path':'close','class':'CCMenuItemSprite','tag':9905,'axes':list(axes),'origin':list(origin)}]}

    def test_equal_rendered_geometry_ignores_device_pixel_density(self):
        mac=self.screen(); phone=self.screen()
        mac['retinaScale']=1; phone['retinaScale']=2
        r=self.report([mac],[phone])
        self.assertEqual(r['differences'],[]); self.assertEqual(r['violations'],[])

    def test_retina_double_size_and_oval_are_detected(self):
        r=self.report([self.screen()],[self.screen((96,0,0,48))])
        self.assertTrue(r['differences']); self.assertTrue(r['violations'])

    def test_missing_screens_are_not_passed(self):
        r=self.report([self.screen()],[])
        self.assertEqual(r['untested'],['tooltip']); self.assertTrue(r['violations'])

    def test_position_drift_is_detected(self):
        r=self.report([self.screen()],[self.screen(origin=(10,0))])
        self.assertEqual(r['differences'][0]['field'],'origin')

if __name__=='__main__': unittest.main()
