import unittest
from gitleaks_config_generator import merge_config

class TestGitleaksConfigGenerator(unittest.TestCase):

    def test_merge_config(self):
        final_config = merge_config('global_config.toml', '.secretsignore')
        self.assertTrue('*.mp3' in final_config['whitelist']['files'])


if __name__ == '__main__':
    unittest.main()
