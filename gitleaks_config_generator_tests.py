import unittest
import gitleaks_config_generator as c


class TestGitleaksConfigGenerator(unittest.TestCase):

    def test_get_final_config_without_secretsignore(self):
        final_config = c.get_final_config('global_config.toml', '')
        self.assertFalse('*.mp3' in final_config['whitelist']['files'])

    def test_get_final_config_with_secretsignore(self):
        final_config = c.get_final_config('global_config.toml',
                                          '.secretsignore')
        self.assertTrue('*.mp3' in final_config['whitelist']['files'])

    def test_merge_config(self):
        final_config = c.merge_config('global_config.toml', '.secretsignore')
        self.assertTrue('*.mp3' in final_config['whitelist']['files'])


if __name__ == '__main__':
    unittest.main()
